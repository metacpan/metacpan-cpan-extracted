package Pod::Usage::CommandLine;

use strict;
use warnings;

our $VERSION = '0.04';

use Pod::Usage;
use Getopt::Long;
use File::Basename;
use base 'Exporter';
our @EXPORT_OK = qw(GetOptions pod2usage);

INIT
{
    Getopt::Long::Parser
    ->new(config => [qw(pass_through no_auto_abbrev no_ignore_case)] )
    ->getoptions
    (
        'help|h|?' => sub { pod2usage(-exitstatus => 0); },
        'man|m'    => sub { pod2usage(-exitstatus => 0, -verbose => 2); },
        version    => sub
        {
            pod2usage(-exitstatus => 0,
                      -msg => basename($0) . ' ' . ($main::VERSION or '0.0'),
                      -verbose => 99,
                      -sections => 'COPYRIGHT.*|LICENSE.*|AUTHOR.*');
        }
    );
}

1;
__END__

=head1 NAME

Pod::Usage::CommandLine - Add some common command line options from Pod::Usage

=head1 SYNOPSIS

  use Pod::Usage::CommandLine;

  BEGIN { our $VERSION = '1.0'; }    # NOTE: Set main version in BEGIN block

  # then, use command line options:

  my_program.pl --version
  my_program.pl --help
  my_program.pl -h
  my_program.pl '-?'
  my_program.pl --man
  my_program.pl -m

  # You can also export GetOptions and/or pod2usage if you need them:

  use Pod::Usage::CommandLine qw(GetOptions pod2usage);

  my %opt;
  GetOptions(\%opt, @getopt_long_specs) or pod2usage;

=head1 DESCRIPTION

Basically a cut/paste from the boilerplate described in Pod::Usage and
Getopt::Long so it can be included with a single "use" instead of
cut/pasting it.

See L<Getopt::Long> for all the intricacies of specifying options.

Set $VERSION in a BEGIN block as shown above so it will get picked up
by the '--version' option.

=head1 EXPORTS

C<GetOptions> and C<pod2usage> are exported on demand.

=head1 SEE ALSO

L<Pod::Usage>, L<Getopt::Long>

=head1 AUTHOR

Curt Tilmes, E<lt>ctilmes@cpan.orgE<gt>

=head1 CREDITS

Thanks to:

Lars Dieckow <daxim@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Curt Tilmes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
