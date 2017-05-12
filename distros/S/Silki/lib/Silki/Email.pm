package Silki::Email;
{
  $Silki::Email::VERSION = '0.29';
}

use strict;
use warnings;

use Email::Date qw( format_date );
use Email::MessageID;
use Email::MIME::CreateHTML;
use Email::Sender::Simple qw( sendmail );
use HTML::Mason::Interp;
use HTML::TreeBuilder;
use MooseX::Params::Validate qw( validated_list );
use Silki::Config;
use Silki::HTML::FormatText;
use Silki::Schema::User;
use Silki::Types qw( Str HashRef );

use Sub::Exporter -setup => { exports => ['send_email'] };

my $Body;
my $Interp;

{
    my $config = Silki::Config->instance();

    my %config = (
        comp_root =>
            $config->share_dir()->subdir('email-templates')->stringify(),
        data_dir =>
            $config->cache_dir()->subdir( 'mason', 'email' )->stringify(),
        error_mode => 'fatal',
        in_package => 'Silki::Mason::Email',
    );

    if ( $config->is_production() ) {
        $config{static_source} = 1;
        $config{static_source_touch_file}
            = $config->etc_dir()->file('mason-touch')->stringify();
    }

    $Interp = HTML::Mason::Interp->new(
        out_method => \$Body,
        %config,
    );
};

sub send_email {
    my ( $from, $to, $subject, $template, $args ) = validated_list(
        \@_,
        from => {
            isa     => Str,
            default => Silki::Schema::User->SystemUser()->email_address(),
        },
        to              => { isa => Str },
        subject         => { isa => Str },
        template        => { isa => Str },
        template_params => {
            isa     => HashRef,
            default => {},
        },
    );

    my $html_body = _execute_template( $template, $args );

    my $text_body = Silki::HTML::FormatText->new( leftmargin => 0 )
        ->format_string($html_body);

    my $version = $Silki::Email::VERSION || 'from working copy';

    my $email = Email::MIME->create_html(
        header => [
            From         => $from,
            To           => $to,
            Subject      => $subject,
            'Message-ID' => Email::MessageID->new()->in_brackets(),
            Date         => format_date(),
            'X-Sender'   => "Silki version $version",
        ],
        body            => $html_body,
        body_attributes => { content_type => 'text/html; charset=utf-8' },
        text_body_attributes =>
            { content_type => 'text/plain; charset=utf-8' },
        text_body => $text_body,
    );

    sendmail($email);

    return;
}

sub _execute_template {
    my $template = shift;
    my $args     = shift;

    $Body = q{};
    $Interp->exec( q{/} . $template . '.html', %{$args} );

    return $Body;
}

{
    package Silki::Mason::Email;
{
  $Silki::Mason::Email::VERSION = '0.29';
}

    use Silki::I18N qw( loc );
    use Silki::Util qw( string_is_empty );
}

1;

# ABSTRACT: Sends email from a template

__END__
=pod

=head1 NAME

Silki::Email - Sends email from a template

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

