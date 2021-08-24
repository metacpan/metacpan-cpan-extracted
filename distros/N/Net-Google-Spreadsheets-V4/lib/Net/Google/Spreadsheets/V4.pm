package Net::Google::Spreadsheets::V4;

use strict;
use warnings;
use 5.010_000;
use utf8;

our $VERSION = '0.003';

use Class::Accessor::Lite (
    new => 0,
    ro  => [qw(ua csv spreadsheet_id endpoint)],
);

use Data::Validator;
use Log::Minimal env_debug => 'NGS4_DEBUG';
use Carp;
use Net::Google::DataAPI::Auth::OAuth2;
use Net::OAuth2::AccessToken;
use Text::CSV;
use Furl;
use JSON;
use Sub::Retry;

sub new {
    state $rule = Data::Validator->new(
        client_id      => { isa => 'Str' },
        client_secret  => { isa => 'Str' },
        refresh_token  => { isa => 'Str' },

        spreadsheet_id => { isa => 'Str' },
        timeout        => { isa => 'Int', default => 120 },
    )->with('Method','AllowExtra');
    my($class, $args) = $rule->validate(@_);

    my $self = bless {
        %$args,
        ua       => undef,
        csv      => Text::CSV->new({ binary => 1}),
        endpoint => 'https://sheets.googleapis.com/v4/spreadsheets/'.$args->{spreadsheet_id},
    }, $class;

    $self->_initialize;

    return $self;
}

sub _initialize {
    my($self) = @_;

    my $account = {
        auth_provider_x509_cert_url => 'https://www.googleapis.com/oauth2/v1/certs',
        auth_uri      => 'https://accounts.google.com/o/oauth2/auth',
        redirect_uris => [
            'urn:ietf:wg:oauth:2.0:oob',
            'http://localhost'
        ],
        token_uri     => 'https://accounts.google.com/o/oauth2/token',
    };

    for my $f (qw(client_id client_secret refresh_token)) {
        $account->{$f} = $self->{$f};
    }

    my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
        client_id     => $account->{client_id},
        client_secret => $account->{client_secret},
        scope => [qw(
                    https://www.googleapis.com/auth/drive
                    https://www.googleapis.com/auth/drive.readonly
                    https://www.googleapis.com/auth/spreadsheets
                    https://www.googleapis.com/auth/spreadsheets.readonly
                )],
    );

    my $ow = $oauth2->oauth2_webserver;
    my $token = Net::OAuth2::AccessToken->new(
        profile       => $ow,
        auto_refresh  => 1,
        refresh_token => $account->{refresh_token},
    );
    $ow->update_access_token($token);
    $token->refresh;
    $oauth2->access_token($token);

    $self->{ua} = Furl->new(
        headers => [ 'Authorization' => sprintf('Bearer %s', $token->access_token) ],
        timeout => $self->{timeout},
    );
}

sub request {
    my($self, $method, $url, $content, $opt) = @_;

    $opt = {
        retry_times    => 3,
        retry_interval => 1.0,
        %{ $opt // {} },
    };

    $url = $self->endpoint . $url;

    debugf("request: %s => %s %s %s", $method, $url, ddf($content//'{no content}'), ddf($opt//'no opt'));

    my $headers = [];
    if ($content) {
        push @$headers, 'Content-Type' => 'application/json';
    }
    if ($opt->{headers}) {
        push @$headers, @{ $opt->{headers} };
    }

    my $res = retry $opt->{retry_times}, $opt->{retry_interval}, sub {
        $self->ua->request(
            method  => $method,
            url     => $url,
            headers => $headers,
            $content ? (content => encode_json($content)) : (),
        );
    }, sub {
        my $res = shift;
        if (!$res) {
            warnf "not HTTP::Response: $@";
            return 1;
        } elsif ($res->status_line =~ /^500\s+Internal Response/
                     or $res->code =~ /^50[234]$/
                 ) {
            warnf 'retrying: %s', $res->status_line;
            return 1; # do retry
        } else {
            return;
        }
    };

    if (!$res) {
        critf 'failure %s %s %s', $method, $url, ddf($content//'{no content}');
        return;
    } else {
        if ($res->is_success) {
            my $res_content = $res->decoded_content ? decode_json($res->decoded_content) : 1;
            return wantarray ? ($res_content, $res) : $res_content;
        } else {
            critf 'failure %s %s %s: %s', $method, $url, ddf($content//'{no content}'), $res->status_line;
            return wantarray ? ('', $res) : '';
        }
    }
}

sub get_sheet {
    state $rule = Data::Validator->new(
        title    => { isa => 'Str', xor => [qw(index sheet_id)] },
        index    => { isa => 'Str', xor => [qw(title sheet_id)] },
        sheet_id => { isa => 'Str', xor => [qw(title index )] },
    )->with('Method');
    my($self, $args) = $rule->validate(@_);

    my($pkey, $akey);
    for my $key (qw(title index sheet_id)) {
        next unless exists $args->{$key};
        $akey = $key;
        $pkey = {
            sheet_id => 'sheetId',
        }->{$key} // $key;
    }

    my($content) = $self->request(GET => '');
    for my $sheet (@{ $content->{sheets} }) {
        if ($sheet->{properties}{$pkey} eq $args->{$akey}) {
            return $sheet;
        }
    }

    return;
}

sub clear_sheet {
    state $rule = Data::Validator->new(
        sheet_id => { isa => 'Str' },
    )->with('Method');
    my($self, $args) = $rule->validate(@_);

    return $self->request(
        POST => ':batchUpdate',
        {
            requests => [
                {
                    repeatCell => {
                        range => {
                            sheetId => $args->{sheet_id},
                        },
                        cell => {
                        },
                        fields => '*',
                    },
                },
            ],
        },
    );
}

# see:
# https://developers.google.com/sheets/guides/concepts#a1_notation
# t/02_a1_notation.t
sub a1_notation {
    state $rule =  Data::Validator->new(
        sheet_title  => { isa => 'Str', optional => 1 },
        start_column => { isa => 'Int', optional => 1 },
        end_column   => { isa => 'Int', optional => 1 },
        start_row    => { isa => 'Int', optional => 1 },
        end_row      => { isa => 'Int', optional => 1 },
    )->with('Method');
    my($self, $args) = $rule->validate(@_);

    my($sheet_title, $start, $end) = ('', '', '');
    if (exists $args->{sheet_title}) {
        $sheet_title = $args->{sheet_title};
        $sheet_title =~ s/'/''/g;
        $sheet_title = sprintf(q{'%s'}, $sheet_title);
    }

    if (exists $args->{start_column}) {
        $start .= $self->column_notation($args->{start_column});
    }
    if (exists $args->{start_row}) {
        $start .= $args->{start_row};
    }

    if (exists $args->{end_column}) {
        $end .= $self->column_notation($args->{end_column});
    }
    if (exists $args->{end_row}) {
        $end .= $args->{end_row};
    }

    if (not $sheet_title) {
        return join(':', $start, $end);
    } elsif (not $start and not $end) {
        return $sheet_title;
    } else {
        return sprintf('%s!%s', $sheet_title, join(':', $start, $end));
    }
}

sub column_notation {
    my($self, $n) = @_;

    my $l = int($n / 27);
    my $r = $n - $l * 26;

    if ($l > 0) {
        return pack 'CC', $l+64, $r+64;
    } else {
        return pack 'C', $r+64;
    }
}

sub to_csv {
    my $self = shift;

    my $status = $self->csv->combine(@_);
    return $status ? $self->csv->string() : ();
}

1;

__END__

=encoding utf8

=begin html

<a href="https://travis-ci.org/hirose31/Net-Google-Spreadsheets-V4"><img src="https://travis-ci.org/hirose31/Net-Google-Spreadsheets-V4.png?branch=master" alt="Build Status" /></a>
<a href="https://coveralls.io/r/hirose31/Net-Google-Spreadsheets-V4?branch=master"><img src="https://coveralls.io/repos/hirose31/Net-Google-Spreadsheets-V4/badge.png?branch=master" alt="Coverage Status" /></a>

=end html

=head1 NAME

Net::Google::Spreadsheets::V4 - Google Sheets API v4 client

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS

    use Net::Google::Spreadsheets::V4;
    
    my $gs = Net::Google::Spreadsheets::V4->new(
        client_id      => "YOUR_CLIENT_ID",
        client_secret  => "YOUR_CLIENT_SECRET",
        refresh_token  => "YOUR_REFRESH_TOKEN",
    
        spreadsheet_id => "YOUR_SPREADSHEET_ID",
    );
    
    my ($content, $res) = $gs->request(
        POST => ':batchUpdate',
        {
            requests => [ ... ],
        },
    );

See also examples/import.pl for more complex code.

=head1 DESCRIPTION

Net::Google::Spreadsheets::V4 is Google Sheets API v4 client

=head1 METHODS

=head2 Class Methods

=head3 B<new>(%args:Hash) :Net::Google::Spreadsheets::V4

Creates and returns a new Net::Google::Spreadsheets::V4 client instance. Dies on errors.

%args is following:

=over 4

=item client_id => Str

=item client_secret => Str

=item refresh_token => Str

=item spreadsheet_id => Str

=back

=head2 Instance Methods

=head3 B<get_sheet>(title|index|sheet_id => Str) :HashRef

Get C<Sheet> object by title or index or sheet_id.

=head3 B<clear_sheet>(sheet_id => Str)

Delete all data.

=head3 B<to_csv>(Array)

Convert Array to CSV Str.

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31@gmail.comE<gt>

=head1 REPOSITORY

L<https://github.com/hirose31/Net-Google-Spreadsheets-V4>

    git clone https://github.com/hirose31/Net-Google-Spreadsheets-V4.git

patches and collaborators are welcome.

=head1 SEE ALSO

L<https://developers.google.com/sheets/>

=head1 COPYRIGHT

Copyright HIROSE Masaaki

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
