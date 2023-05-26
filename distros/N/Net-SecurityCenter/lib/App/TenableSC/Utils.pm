package App::TenableSC::Utils;

use strict;
use warnings;

use Carp;
use File::Basename;
use Term::ReadKey;

use Exporter qw(import);

our $VERSION = '0.311';

our @EXPORT_OK = qw(

    config_parse_line
    config_parser

    file_slurp
    trim
    dumper

    cli_version
    cli_error
    cli_readkey

);

our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

sub cli_error {

    my ($error) = @_;
    $error =~ s/ at .* line \d+.*//;

    my $script_name = basename($0);

    print "$script_name ERROR: $error\n";

    exit(255);

}

sub cli_readkey {

    my ($message) = @_;

    my $value = undef;

    print $message;
    ReadMode 'noecho';

    $value = ReadLine 0;
    chomp $value;

    ReadMode 'normal';
    print "\n";

    return $value;

}

sub cli_version {

    require IO::Socket::SSL;
    require LWP::UserAgent;
    require Net::SecurityCenter;
    require App::TenableSC;

    my $io_socket_ssl = ($IO::Socket::SSL::VERSION) ? $IO::Socket::SSL::VERSION : 'n/a';
    my $lwp_useragent = ($LWP::UserAgent::VERSION)  ? $LWP::UserAgent::VERSION  : 'n/a';
    my $script_name   = basename($0);

    print <<"EOF";
$script_name v$VERSION

CORE
  Perl                ($^V, $^O)
  Net::SecurityCenter ($Net::SecurityCenter::VERSION)
  App::TenableSC      ($App::TenableSC::VERSION)

MODULES
  LWP::UserAgent      ($lwp_useragent)
  IO::Socket::SSL     ($io_socket_ssl)

EOF

    exit 0;

}

sub trim {
    Net::SecurityCenter::Utils::trim(@_);
}

sub dumper {
    Net::SecurityCenter::Utils::dumper(@_);
}

sub file_slurp {

    my ($file) = @_;

    open my $fh, '<', $file or croak("Can't open $file file: $!");

    my $string = do {
        local $/ = undef;
        <$fh>;
    };

    close $fh or croak("Failed to close $file file: $!");

    return $string;

}

#-------------------------------------------------------------------------------

sub config_parse_line {

    my ($value) = @_;

    return 1 if ( $value =~ m/^(yes|true)$/s );
    return 0 if ( $value =~ m/^(no|false)$/s );

    if ( $value =~ /\,/ ) {
        return map { trim($_) } split /,/, $value;
    }

    return $value;

}

#-------------------------------------------------------------------------------

sub config_parser {

    my ($config_string) = @_;

    my $section     = '_';    # Root section
    my $config_data = {};

    foreach my $line ( split /\n/, $config_string ) {

        chomp($line);

        # skip comments and empty lines
        next if ( $line =~ m/^\s*([#;])/ );
        next if ( $line =~ m/^\s*$/ );

        if ( $line =~ m/^\[(.*)\]\s*$/ ) {
            $section = trim($1);
            next;
        }

        if ( $line =~ m/^([^=]+?)\s*=\s*(.*?)\s*$/ ) {

            my ( $field, $raw_value ) = ( $1, $2 );
            my $parsed_value = [ config_parse_line($raw_value) ];

            my $value = ( ( @{$parsed_value} == 1 ) ? $parsed_value->[0] : $parsed_value );

            if ( not defined $section ) {
                $config_data->{$field} = $value;
                next;
            }

            $config_data->{$section}->{$field} = $value;

        }

    }

    return $config_data;

}

1;

=pod

=encoding UTF-8


=head1 NAME

App::TenableSC::Utils - Utilities for App::TenableSC


=head1 SYNOPSIS

    use App::TenableSC::Utils qw(:all);

    print dumper( { 'foo' => 'bar' } );


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 METHODS


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
