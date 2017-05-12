package App::mbxilinx;

use 5.0008;
use strict;
use warnings;
use YAML qw/LoadFile/;
use Module::Build::Xilinx;

our $VERSION = '0.13';
$VERSION = eval $VERSION;

sub process {
    my ($self, $yml) = @_;
    my $data = LoadFile($yml);
    die "YAML data is not a hash reference" unless ref $data eq 'HASH';
    my $build = Module::Build::Xilinx->new(%$data);
    $build->create_build_script;
    1;
}

__END__
#### COPYRIGHT: 2014. Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 11th July 2014

=head1 NAME

App::mbxilinx - Module to invoke the Module::Xilinx::Build class with a YAML
file and generate Build

=head1 VERSION

0.13

=head1 SYNOPSIS

    use App::mbxilinx;
    App::mbxilinx->process('build.yml');

=head1 FUNCTIONS

=over

=item B<process(YML)>

The C<process()> function takes only 1 argument and that is the YAML filename to
load.

The invocation of the function is as follows:

    App::mbxilinx->process('myfile.yml');

=back

=head1 THE YAML FILE

The YAML file required here may be titled B<build.yml> or could be anything
else. By default if you just run L<mbxilinx> without any arguments it will look
for C<build.yml> in the current directory or fail or if you have a use case
where you may need to use it from another module, you could use L<App::mbxilinx> instead.

A sample C<build.yml> is present in the C<share/example> directory in the source
code which we shall reproduce here

    ---
    dist_name: dflipflops
    dist_version: '0.01'
    dist_author: 'Vikas N Kumar <vikas@cpan.org>'
    dist_abstract: 'This is a test'
    proj_params:
        family: spartan3a
        device: xc3s700a
        package: fg484
        speed: -4
        language: VHDL


The L<mbxilinx> program using the L<App::mbxilinx> module just parses the input
YAML file and then calls L<Module::Build::Xilinx> to create the C<Build> script
for use by the user as given in the L<Module::Build::Xilinx> documentation.

=head1 SEE ALSO

L<Module::Build::Xilinx>, L<mbxilinx>

=head1 AUTHOR

Vikas Kumar, E<lt>vikas@cpan.orgE<gt>

=head1 CONTACT

Find me on IRC: I<#hardware> on L<irc://irc.perl.org> as user name B<vicash>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Vikas Kumar

This library is under the MIT license. Please refer the LICENSE file for more
information provided with the distribution.

=cut
