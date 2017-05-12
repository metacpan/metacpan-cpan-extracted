# from florian ragwitz --r
use Carp 'croak';
use Sub::Install 'reinstall_sub';
use B::Hooks::EndOfScope;
use namespace::clean ();
use namespace::autoclean;

sub autoclean_installer {
    my ($arg, $to_export) = @_;

    for (my $i = 0; $i < @$to_export; $i += 2) {
        my ($as, $code) = @$to_export[ $i, $i+1 ];

        if (ref $as eq 'SCALAR') {
            $$as = $code;
        }
        elsif (ref $as) {
            croak "invalid reference type for $as: " . ref $as;
        }
        else {
            reinstall_sub({
                code => $code,
                into => $arg->{into},
                as   => $as,
            });

            on_scope_end {
                namespace::clean->clean_subroutines($arg->{into}, $as);
            };
        }
    }
}

