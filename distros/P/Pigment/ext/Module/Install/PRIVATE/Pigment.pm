use strict;
use warnings;

package Module::Install::PRIVATE::Pigment;

use base qw/Module::Install::Base/;

use Gtk2::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;
use File::Spec::Functions qw/catfile rel2abs/;

sub pigment {
    my ($self) = @_;

    mkdir 'build';

    my %pkgconfig = (cflags => q{}, libs => q{});
    for my $pkg (qw/pigment-gtk-0.3 pigment-imaging-0.3/) {
        my %pkg;
        eval {
            %pkg = ExtUtils::PkgConfig->find($pkg);
        };

        if (my $error = $@) {
            print STDERR $error;
            return;
        }

        $pkgconfig{$_} .= q{ } . $pkg{$_} for qw/cflags libs/;
    }

    Glib::CodeGen->add_type_handler(
        PgmEvent => sub {
            my ($typemacro, $classname, $base, $package) = @_;
	        Glib::CodeGen::add_header "#ifdef $typemacro
  /* GBoxed $classname */
  typedef $classname $classname\_ornull;
# define Sv$classname(sv)	(($classname *) gperl_get_boxed_check ((sv), $typemacro))
# define Sv$classname\_ornull(sv)	(gperl_sv_is_defined (sv) ? Sv$classname (sv) : NULL)
  typedef $classname $classname\_own;
  typedef $classname $classname\_copy;
  typedef $classname $classname\_own_ornull;
# define newSV$classname(val)	(gperl_new_boxed ((gpointer) (val), $typemacro, FALSE))
# define newSV$classname\_ornull(val)	((val) ? newSV$classname(val) : &PL_sv_undef)
# define newSV$classname\_own(val)	(gperl_new_boxed ((gpointer) (val), $typemacro, TRUE))
# define newSV$classname\_copy(val)	(gperl_new_boxed_copy ((gpointer) (val), $typemacro))
# define newSV$classname\_own_ornull(val)	((val) ? newSV$classname\_own(val) : &PL_sv_undef)
#endif /* $typemacro */
";
            Glib::CodeGen::add_typemap "$classname *", "T_GPERL_GENERIC_WRAPPER";
	        Glib::CodeGen::add_typemap "const $classname *", "T_GPERL_GENERIC_WRAPPER";
	        Glib::CodeGen::add_typemap "$classname\_ornull *", "T_GPERL_GENERIC_WRAPPER";
	        Glib::CodeGen::add_typemap "const $classname\_ornull *", "T_GPERL_GENERIC_WRAPPER";
	        Glib::CodeGen::add_typemap "$classname\_own *", "T_GPERL_GENERIC_WRAPPER";
	        Glib::CodeGen::add_typemap "$classname\_copy *", "T_GPERL_GENERIC_WRAPPER";
	        Glib::CodeGen::add_typemap "$classname\_own_ornull *", "T_GPERL_GENERIC_WRAPPER";
	        Glib::CodeGen::add_register "#ifdef $typemacro
gperl_register_boxed ($typemacro, \"$package\", perl_pigment_get_element_wrapper_class ());
#endif /* $typemacro */";
        },
    );

    Gtk2::CodeGen->parse_maps('pigment');
    Gtk2::CodeGen->write_boot(ignore => qr/^Pigment$/);

    our @xs_files = <xs/*.xs>;

    our $pigment = ExtUtils::Depends->new('Pigment', 'Gtk2', 'GStreamer');
    $pigment->set_inc($pkgconfig{cflags});
    $pigment->set_libs($pkgconfig{libs});
    $pigment->add_xs(@xs_files);
    $pigment->add_c('perl_pigment.c');
    $pigment->add_pm('lib/Pigment.pm' => '$(INST_LIBDIR)/Pigment.pm');
    $pigment->add_typemaps(rel2abs(catfile(qw/build pigment.typemap/)));
    $pigment->install(catfile(qw/build pigment-autogen.h/));
    $pigment->save_config(catfile(qw/build IFiles.pm/));

    $self->makemaker_args(
        $pigment->get_makefile_vars,
        XSPROTOARG => '-noprototypes',
        MAN3PODS => { Glib::MakeHelper->do_pod_files(@xs_files) },
    );

    $self->postamble(
        Glib::MakeHelper->postamble_clean
      . Glib::MakeHelper->postamble_docs_full(
          DEPENDS => $pigment, XS_FILES => \@xs_files,
          COPYRIGHT => 'Copyright (c) 2009  Florian Ragwitz'
        )
    );

    return 1;
}

1;
