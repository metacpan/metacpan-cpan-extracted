package PAR::Repository::Web;
use strict;
use warnings;
our $VERSION = '0.03';

use PAR::Dist ();

#use Catalyst qw/-Debug ConfigLoader Static::Simple/;
use Catalyst qw/ConfigLoader Static::Simple /;

#
# Configure the application 
#
__PACKAGE__->config(
    name => 'PAR::Repository::Web',
    'View::TToolkit' => {
        INCLUDE_PATH => __PACKAGE__->path_to('templates'),
    }
);


#
# Start the application
#
__PACKAGE__->setup;

1;

__END__

=head1 NAME

PAR::Repository::Web - A simple web viewer for PAR::Repository

=head1 SYNOPSIS

    cp examples/par_repository_web.yml .
    cp -r examples/testrepo .
    script/par_repository_web_server.pl

=head1 DESCRIPTION

PAR::Repository::Web is a simple (read-only) web interface to a L<PAR::Repository>.
It can display the contents of one or more repositories, both local and remote.
The displayed information includes the list of distributions, scripts and modules provided.

=head1 SEE ALSO

L<PAR::Repository>, L<PAR::Repository::Client>, L<PAR::Repository::Query>, L<PAR::Dist>

L<Catalyst>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

