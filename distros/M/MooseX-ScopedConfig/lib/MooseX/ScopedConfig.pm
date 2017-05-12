package MooseX::ScopedConfig;

use 5.006;
use Moose::Role;
use Config::Scoped;
with 'MooseX::ConfigFromFile';

=head1 NAME

MooseX::ScopedConfig - Moose eXtension to use Config::Scoped

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

MooseX::ScopedConfig is to Config::Scoped as MooseX::SimpleConfig is to Config::Any

    package My::AwesomePackage;
    use Moose;
    with 'MooseX::ScopedConfig';

    # optional, default config file name
    sub configfile { '/tmp/application.cfg' }

    # a script useing your awesome (configurable) package
    
    use My::AwesomePackage;
    my $ap = My::AwesomePackage->new_with_config(configfile => '/tmp/app.cfg');
    ...

=head1 SUBROUTINES/METHODS

=head2 get_config_from_file

get_config_from_file does the real work tying Config::Scoped to MooseX::ConfigFromFile

=cut

sub get_config_from_file {
  my ($self, $file) = @_;
  $file = $file->() if (ref($file) eq 'CODE');
  my $cs = Config::Scoped->new(file => $file, warnings => { parameters => 'off' });
  my $cfg = $cs->parse();
  return $cfg;
}

=head1 AUTHOR

brad barden, C<< <iamb at mifflinet.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-scopedconfig at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-ScopedConfig>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::ScopedConfig


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-ScopedConfig>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-ScopedConfig>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-ScopedConfig>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-ScopedConfig/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 brad barden.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

no Moose::Role;

1; # End of MooseX::ScopedConfig
