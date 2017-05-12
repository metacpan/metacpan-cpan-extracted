use strict;
use warnings;

use Test::More 0.96;
use Test::Without::Module 'Ref::Util';

use Specio::Library::Builtins;

my @types = qw(
    ArrayRef
    CodeRef
    FileHandle
    GlobRef
    HashRef
    Object
    RegexpRef
    ScalarRef
);

for my $t (@types) {
    my $inline = t($t)->_inline_generator('$_[0]');
    unlike(
        $inline,
        qr/Ref::Util/,
        "inline code for $t does not use Ref::Util when it is not available"
    );
}

open my $fh, '<', 't/builtins-sanity.t' or die $!;
## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
eval do { local $/ = undef; <$fh> };
die $@ if $@;
close $fh or die $!;
