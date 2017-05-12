package Net::Amazon::MechanicalTurk::Template::PerlTemplate;
use strict;
use warnings;
use Carp;
use IO::File;
use IO::String;
use Net::Amazon::MechanicalTurk::Template;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::Template };

Net::Amazon::MechanicalTurk::Template::PerlTemplate->attributes(qw{
    compiledSub
});

sub compileSource {
    my ($self, $text) = @_;
    
    # Wrap the code in an anonymouse sub, so it only has to be eval'd once.
    my $perlSource =
        "return sub {\n" .
        "    my \$out = shift;\n" .
        "    my \%params = \%{\$_[0]};\n" .
        $text . "\n" .
        "}\n";

    $self->compiledSub(Net::Amazon::MechanicalTurk::Template::PerlTemplate::CompiledNameSpace::__compileSub__(
        $perlSource,
        $self->templateFile
    ));
    $self->compiled(1);
}

sub merge {
    my ($self, $params) = @_;
    my $out = IO::String->new;
    my $oldFh = select($out);
    eval {
        $self->compiledSub->($out, $params);
    };
    if ($@) {
        my $error = $@;
        select($oldFh);
        Carp::croak("Error executing perl template " . $self->templateFile . " - $error.");
    }
    select($oldFh);
    return ${$out->string_ref};
}

package Net::Amazon::MechanicalTurk::Template::PerlTemplate::CompiledNameSpace;

our $VERSION = '1.00';

# provides a package to be used for evaluating code.
# A perl template may declare subs.  If they are not qualified they will end up 
# in here.
# 
# WARNING:
#   If a user compiles more than 1 template where more than 1 template has
#   has a common subroutine name, then the last compiled template will be the
#   one providing the implementation of the sub, for all templates.
#

sub __compileSub__ {
    # Use funky variable names to avoid clashing with template variables.
    my $__perlSource__ = shift;
    my $__perlSourceFile__ = shift;
    no warnings;
    my $__perlSub__ = eval $__perlSource__;
    if ($@) {
        Carp::croak("Couldn't compile perl source from $__perlSourceFile__ - $@.");
    }
    if (!UNIVERSAL::isa($__perlSub__, "CODE")) {
        Carp::croak("Couldn't find compiled code in perl source $__perlSourceFile__.");
    }
    return $__perlSub__;
}

return 1;
