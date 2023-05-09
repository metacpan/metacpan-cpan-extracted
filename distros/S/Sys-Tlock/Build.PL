# Tlock/Build.PL
use Module::Build;
use strict;
use 5.030000;

my $class = Module::Build->subclass(
    class => 'Custom' ,
    code => q[
        sub ACTION_install {
            my $self = shift;
            use File::Copy qw(copy);

            my $home = $self->SUPER::install_destination('script').'/tlock.d/';

            # Module::Build should be able to do this automatically?
            # But it is unclear from the documentation...
            open my $cm , '>' , 'blib/lib/Sys/Tlock/Config.pm';
            print $cm qq[

# Sys::Tlock::Config.pm
# Do not modify. Overwritten at install time.

package Config;
use strict;

our \$home = '${home}';

1;
__END__

                ] =~ s/^\s+//r =~ s/\s+$//r;
            close $cm;

            $self->SUPER::ACTION_install;

            mkdir $home if not -d $home;
            chmod oct(1755) , $home;
            unlink $home.'default.conf' if -f $home.'default.conf';
            copy( 'tlock.conf' , $home.'default.conf' );
            chmod 0744 , $home.'default.conf';
            mkdir $home.'locks/' if not -d $home.'locks/';
            chmod 0777 , $home.'locks/';
            }
        ] ,
    );

$class->new(
    module_name         => 'Sys::Tlock' ,
    license             => 'apache' ,
    dist_author         => 'Bjoern Hee <github@spredehagl.com>' ,
    dist_abstract       => 'Locks with timeouts.' ,
    create_makefile_pl  => 0 ,
    script_files        => 'script' ,
    create_readme       => 0 ,
    requires            => {
        'File::Basename' => '0' ,
        'Time::HiRes'    => '0' ,
        } ,
    configure_requires => {
        'Module::Build' => 0.42 ,
        } ,
    meta_merge => {
        resources => {
            repository => 'https://github.com/spragl/Tlock' ,
            bugtracker => 'https://github.com/spragl/Tlock/issues' ,
            } ,
        } ,
    )->create_build_script;

