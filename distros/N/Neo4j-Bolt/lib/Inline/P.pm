package
  Inline::P;
use base Inline::C;
use Config;
our $VERSION = '0.01';
print "HEY\n";

sub register {
  return {
    language => 'P',
    type => 'compiled',
    suffix => $Config{dlext}
   }
}

# sub validate {
#   my $o = shift;
#   $o->SUPER::validate(@_);
# }

sub write_Makefile_PL {
  my $o = shift;
  $o->{ILSM}{xsubppargs} = '';
  my $i = 0;
    for (@{$o->{ILSM}{MAKEFILE}{TYPEMAPS}}) {
        $o->{ILSM}{xsubppargs} .= "-typemap \"$_\" ";
    }
  # here munge {ILSM}{MAKEFILE}{INC} to remove superfluous quotes and
  # dups
    print STDERR "Inline::C patch write_Makefile_PL\n";
    $o->{ILSM}{MAKEFILE}{INC} =~ s{"(-.*?-\S+)"}{$1}g;
  $o->{ILSM}{MAKEFILE}{INC} =~ s{-fvisibility=hidden}{};
    my %options = (
        VERSION => $o->{API}{version} || '0.00',
        %{$o->{ILSM}{MAKEFILE}},
        NAME => $o->{API}{module},
    );

    open MF, "> ".File::Spec->catfile($o->{API}{build_dir},"Makefile.PL")
        or croak;

    print MF <<END;
use ExtUtils::MakeMaker;
my %options = %\{
END

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    print MF Data::Dumper::Dumper(\ %options);

    print MF <<END;
\};
WriteMakefile(\%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
END
    close MF;
}

1;
