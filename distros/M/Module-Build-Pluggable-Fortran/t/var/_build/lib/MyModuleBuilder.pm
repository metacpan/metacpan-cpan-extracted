package MyModuleBuilder;
use Module::Build;
@ISA = qw(Module::Build);

        use Module::Build::Pluggable;
        sub resume {
            my $class = shift;
            my $self = $class->SUPER::resume(@_);
            Module::Build::Pluggable->call_triggers_all('build', $self, [['Module::Build::Pluggable::Fortran',undef]]);
            $self;
        }
    
1;
