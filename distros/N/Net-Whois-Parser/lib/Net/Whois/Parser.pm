package Net::Whois::Parser;

use strict;

use utf8;
use Net::Whois::Raw;
use Data::Dumper;

our $VERSION = '0.08';

our @EXPORT = qw( parse_whois );

our $DEBUG = 0;

# parsers for parse whois text to data structure
our %PARSERS = (
    'DEFAULT' => \&_default_parser,
);

# rules to convert diferent names of same fields to standard name
our %FIELD_NAME_CONV = (

    # nameservers
    nserver          => 'nameservers',
    name_server      => 'nameservers',
    name_serever     => 'nameservers',
    name_server      => 'nameservers',
    nameserver       => 'nameservers',
    dns1             => 'nameservers',
    dns2             => 'nameservers',
    primary_server   => 'nameservers',
    secondary_server => 'nameservers',

    # domain
    domain_name   => 'domain',
    domainname    => 'domain',

    # creation_date
    created                  => 'creation_date',
    created_on               => 'creation_date',
    creation_date            => 'creation_date',
    domain_registration_date => 'creation_date',
    domain_created           => 'creation_date',

    #expiration_date
    expire                 => 'expiration_date',
    expire_date            => 'expiration_date',
    expires                => 'expiration_date',
    expires_at             => 'expiration_date',
    expires_on             => 'expiration_date',
    expiry_date            => 'expiration_date',
    domain_expiration_date => 'expiration_date',

);

# You can turn this flag to get
# all values of field in all whois answers
our $GET_ALL_VALUES = 0;

# hooks for formating values
our %HOOKS = (
    nameservers => [ \&format_nameservers ],
    emails => [ sub {my $value = shift; ref $value ? $value : [$value] } ],
);

# From Net::Whois::Raw
sub import {
    my $mypkg = shift;
    my $callpkg = caller;

    no strict 'refs';

    # export subs
    *{"$callpkg\::$_"} = \&{"$mypkg\::$_"} foreach ((@EXPORT, @_));
}

# fetches whois text
sub _fetch_whois {
    my %args = @_;

    local $Net::Whois::Raw::CHECK_FAIL = 1;

    my @res = eval {
        Net::Whois::Raw::whois(
            $args{domain},
            $args{server} || undef,
            $args{which_whois} || 'QRY_ALL'
        )
    };
    return undef if $@;

    my $res = ref $res[0] ? $res[0] : [ { text => $res[0], srv => $res[1] } ];
    @$res = grep { $_->{text} } @$res;

    return scalar @$res ? $res : undef;
}

sub parse_whois {
    #TODO warn: Odd number of elements in hash assignment
    my %args = @_;

    if ( $args{raw} ) {

        my $server =
            $args{server} ||
            Net::Whois::Raw::Common::get_server($args{domain}) ||
            'DEFAULT';

        my $whois = ref $args{raw} ? $args{raw} : [ { text => $args{raw}, srv => $server } ];

        return _process_parse($whois);

    }
    elsif ( $args{domain} ) {
        my $whois = _fetch_whois(%args);
        return $whois ? _process_parse($whois) : undef;
    }

    undef;
}

sub _process_parse {
    my ( $whois ) = @_;

    my @data = ();
    for my $ans ( @$whois ) {

        my $parser =
            $ans->{srv} && $PARSERS{$ans->{srv}} ?
                $PARSERS{$ans->{srv}} : $PARSERS{DEFAULT};

        push @data, $parser->($ans->{text});
    }

    _post_parse(\@data);
}

# standardize data structure
sub _post_parse {
    my ( $data )  = @_;

    my %res = ();
    my $count = 0;
    my %flag = ();

    for my $hash ( @$data ) {

        $count++;

        for my $key ( keys %$hash ) {
            next unless $hash->{$key};

            # change keys to standard names
            my $new_key = lc $key;
            $new_key =~ s/\s+|\t+|-/_/g;
            $new_key =~ s/\.+$//;
            if ( exists $FIELD_NAME_CONV{$new_key} ) {
                $new_key =  $FIELD_NAME_CONV{$new_key};
            }

            unless ( $GET_ALL_VALUES ) {
                if ( exists $res{$new_key} && !$flag{$new_key} ) {
                    delete $res{$new_key};
                    $flag{$new_key} = 1;
                }
            }

            # add values to result hash
            if ( exists $res{$new_key} ) {
                push @{$res{$new_key}}, @{$hash->{$key}};
            }
            else {
                $res{$new_key} = ref $hash->{$key} ? $hash->{$key} : [$hash->{$key}];
            }

        }
    }

    # make unique and process hooks
    while ( my ( $key, $value ) = each %res ) {

        if ( scalar @$value > 1 ) {
            @$value = _make_unique(@$value);
        }
        else {
            $value = $value->[0];
        }

        if ( exists $HOOKS{$key} ) {
            for my $hook ( @{$HOOKS{$key}} ) { $value = $hook->($value) }
        }

        $res{$key} = $value;

    }

    \%res;
}

sub _make_unique {
    my %vals;
    grep { not $vals{$_} ++ } @_;
}

## PARSERS ##

# Regular expression built using Jeffrey Friedl's example in
# _Mastering Regular Expressions_ (http://www.ora.com/catalog/regexp/).

my $RFC822PAT = <<'EOF';
[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\
xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xf
f\n\015()]*)*\)[\040\t]*)*(?:(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\x
ff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"[^\\\x80-\xff\n\015
"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[\040\t]*(?:\([^\\\x80-\
xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80
-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*
)*(?:\.[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\
\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\
x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x8
0-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"[^\\\x80-\xff\n
\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[\040\t]*(?:\([^\\\x
80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^
\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040
\t]*)*)*@[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([
^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\
\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\
x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-
\xff\n\015\[\]]|\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()
]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\
x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\04
0\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\
n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\
015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?!
[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\
]]|\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\
x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\01
5()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)*|(?:[^(\040)<>@,;:".
\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]
)|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[^
()<>@,;:".\\\[\]\x80-\xff\000-\010\012-\037]*(?:(?:\([^\\\x80-\xff\n\0
15()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][
^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)|"[^\\\x80-\xff\
n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[^()<>@,;:".\\\[\]\
x80-\xff\000-\010\012-\037]*)*<[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?
:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-
\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:@[\040\t]*
(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015
()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()
]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\0
40)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\
[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\
xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*
)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80
-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x
80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t
]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\
\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])
*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x
80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80
-\xff\n\015()]*)*\)[\040\t]*)*)*(?:,[\040\t]*(?:\([^\\\x80-\xff\n\015(
)]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\
\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*@[\040\t
]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\0
15()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015
()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(
\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|
\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80
-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()
]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x
80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^
\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040
\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".
\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff
])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\
\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x
80-\xff\n\015()]*)*\)[\040\t]*)*)*)*:[\040\t]*(?:\([^\\\x80-\xff\n\015
()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\
\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)?(?:[^
(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-
\037\x80-\xff])|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\
n\015"]*)*")[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|
\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))
[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80-\xff
\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\x
ff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(
?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\
000-\037\x80-\xff])|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\
xff\n\015"]*)*")[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\x
ff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)
*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)*@[\040\t]*(?:\([^\\\x80-\x
ff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-
\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)
*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\
]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\]
)[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-
\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\x
ff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(
?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80
-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<
>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x8
0-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\])[\040\t]*(?:
\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]
*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)
*\)[\040\t]*)*)*>)
EOF

$RFC822PAT =~ s/\n//g;


sub _default_parser {
    my ( $raw ) = @_;
    my %data;

    # transform data to key => value
    for my $line ( split /\n/, $raw ) {

        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        my ( $key, $value ) = $line =~ /^\s*([\d\w\s._-]+):\s*(.+)$/;
        next if  !$line || !$value;
        $key =~ s/\s+$//;
        $value =~ s/\s+$//;

        # if we have more then one value for one field we push them into array
        $data{$key} = ref $data{$key} eq 'ARRAY' ?
            [ @{$data{$key}}, $value ] : [ $value ];

    }

    # find all emails in the text
    my @emails = $raw =~ /($RFC822PAT)/gso;
    @emails = map { $_ =~ s/\s+//g; ($_) } @emails;
    $data{emails} = exists $data{emails} ?
        [ @{$data{emails}}, @emails ] : \@emails;

    \%data;
}

## FORMATERS ##

sub format_nameservers {
    my ( $value ) = @_;

    $value = [$value] unless ref $value;

    my @nss;
    for my $ns ( @$value ) {
        my ( $domain, $ip ) = split /\s+/, $ns;

        $domain ||= $ns;
        $domain =~ s/\.$//;
        $domain = lc $domain;

        push @nss, {
            domain => $domain,
            ( $ip ? (ip => $ip) : () )
        };
    }

    \@nss;
}

1;

=head1 NAME

Net::Whois::Parser - module for parsing whois information

=head1 SYNOPSIS

    use Net::Whois::Parser;

    my $info = parse_whois( domain => $domain );
    my $info = parse_whois( raw => $whois_raw_text, domain => $domain  );
    my $info = parse_whois( raw => $whois_raw_text, server => $whois_server  );

    $info = {
        nameservers => [
            { domain => 'ns.example.com', ip => '123.123.123.123' },
            { domain => 'ns.example.com' },
        ],
        emails => [ 'admin@example.com' ],
        domain => 'example.com',
        somefield1 => 'value',
        somefield2 => [ 'value', 'value2' ],
        ...
    };

    # Your own parsers

    sub my_parser {
        my ( $text ) = @_;
        return {
            nameservers => [
                { domain => 'ns.example.com', ip => '123.123.123.123' },
                { domain => 'ns.example.com' },
            ],
            emails => [ 'admin@example.com' ],
            somefield => 'value',
            somefield2 => [ 'value', 'value2' ],
        };
    }

    $Net::Whois::Parser::PARSERS{'whois.example.com'} = \&my_parser;
    $Net::Whois::Parser::PARSERS{'DEFAULT'}           = \&my_default_parser;

    # If you want to get all values of fields from all whois answers
    $Net::Whois::Parser::GET_ALL_VALUES = 1;
        # example
        # Net::Whois::Raw returns 2 answers
        $raw = [ { text => 'key: value1' }, { text => 'key: value2'}];
        $data = parse_whois(raw => $raw);
        # If flag is off parser returns
        # { key => 'value2' };
        # If flag is on parser returns
        # { key => [ 'value1', 'value2' ] };

    # If you want to convert some field name to another:
    $Net::Whois::Parser::FIELD_NAME_CONV{'Domain name'} = 'domain';

    # If you want to format some fields.
    # I think it is very useful for dates.
    $Net::Whois::Parser::HOOKS{'expiration_date'} = [ \&format_date ];

=head1 DESCRIPTION

Net::Whois::Parser module provides Whois data parsing.
You can add your own parsers for any whois server.

=head1 FUNCTIONS

=over 3

=item parse_whois(%args)

Returns hash of whois data. Arguments:

C<'domain'> -
    domain

C<'raw'> -
    raw whois text

C<'server'> -
   whois server

C<'which_whois'> -
    option for Net::Whois::Raw::whois. Default value is QRY_ALL

=back

=head1 CHANGES

See file "Changes" in the distribution

=head1 AUTHOR

Ivan Sokolov, C<< <ivsokolov@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ivan Sokolov

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
