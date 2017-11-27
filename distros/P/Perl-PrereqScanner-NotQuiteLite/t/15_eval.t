use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('if (eval)', <<'END', {}, {'Test::More' => 0});
if ( eval "require 'Test/More.pm';" ) { }
END

test('eval()', <<'END', {}, {'Test::More' => 0});
eval('use Test::More');
END

test('eval{"string"}', <<'END', {}, {});
eval{'use Test::More'};
END

test('eval heredoc', <<'END', {}, {'Test::More' => 0});
eval <<'EOF';
require Test::More;
EOF
END

# adapted from NWELLNHOF/Lucy-0.6.1/buildlib/Lucy/Build/Binding/Misc.pm
test('eval $VARIABLE (should not rescan the inside of the following heredoc)', <<'END', {strict => 0, warnings => 0}, {});
package Lucy::Build::Binding::Misc;
use strict;
use warnings;

our $VERSION = '0.006001';
$VERSION = eval $VERSION;

# (snip)

sub bind_simple {
    my @hand_rolled = qw( Add_Doc );

    $pod_spec->set_synopsis($synopsis);

    $pod_spec->add_constructor( sample => $constructor );
    # Override is necessary because there's no standard way to explain
    # hash/hashref across multiple host languages.
    $pod_spec->add_method(
        method => 'Add_Doc',
        alias  => 'add_doc',
        pod    => $add_doc_pod,
    );

    my $xs_code = <<'END_XS_CODE';
MODULE = Lucy  PACKAGE = Lucy::Simple

void
add_doc(self, doc_sv)
    lucy_Simple *self;
    SV *doc_sv;
PPCODE:
{
    lucy_Doc *doc = NULL;

    // Either get a Doc or use the stock doc.
    if (sv_isobject(doc_sv)
        && sv_derived_from(doc_sv, "Lucy::Document::Doc")
       ) {
        IV tmp = SvIV(SvRV(doc_sv));
        doc = INT2PTR(lucy_Doc*, tmp);
    }
    else if (XSBind_sv_defined(aTHX_ doc_sv) && SvROK(doc_sv)) {
        HV *maybe_fields = (HV*)SvRV(doc_sv);
        if (SvTYPE((SV*)maybe_fields) == SVt_PVHV) {
            lucy_Indexer *indexer = LUCY_Simple_Get_Indexer(self);
            doc = LUCY_Indexer_Get_Stock_Doc(indexer);
            LUCY_Doc_Set_Fields(doc, maybe_fields);
        }
    }
    if (!doc) {
        THROW(CFISH_ERR, "Need either a hashref or a %o",
              CFISH_Class_Get_Name(LUCY_DOC));
    }

    LUCY_Simple_Add_Doc(self, doc);
}
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Simple",
    );
    $binding->exclude_method($_) for @hand_rolled;
    $binding->append_xs($xs_code);
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

END

test('eval()', <<'END', {}, {'GD::Simple' => 0});
my $load_this_package=eval("require GD::Simple;");
END

# TONYC/Imager-1.006/Imager.pm
test('eval ()', <<'END', {}, {'Affix::Infix2Postfix' => 0});
sub transform {
  my $self=shift;
  my %opts=@_;
  my (@op,@ropx,@ropy,$iop,$or,@parm,$expr,@xt,@yt,@pt,$numre);

#  print Dumper(\%opts);
#  xopcopdes

  $self->_valid_image("transform")
    or return;

  if ( $opts{'xexpr'} and $opts{'yexpr'} ) {
    if (!$I2P) {
      {
	local @INC = @INC;
	pop @INC if $INC[-1] eq '.';
	eval ("use Affix::Infix2Postfix;");
      }
    }
  }
}
END

test('use after eval $VERSION', <<'END', {strict => 0, Carp => 0});
use strict;
our $VERSION = '7.24';
$VERSION = eval $VERSION;

use Carp;
END

done_testing;
