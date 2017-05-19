#line 1
use strict;
use warnings;

package B::Hooks::EndOfScope;
BEGIN {
  $B::Hooks::EndOfScope::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $B::Hooks::EndOfScope::VERSION = '0.09';
}
# ABSTRACT: Execute code after a scope finished compilation

use 5.008000;
use Variable::Magic 0.34;

use Sub::Exporter -setup => {
    exports => ['on_scope_end'],
    groups  => { default => ['on_scope_end'] },
};



{
    my $wiz = Variable::Magic::wizard
        data => sub { [$_[1]] },
        free => sub { $_->() for @{ $_[1] }; () };

    sub on_scope_end (&) {
        my $cb = shift;

        $^H |= 0x020000;

        if (my $stack = Variable::Magic::getdata %^H, $wiz) {
            push @{ $stack }, $cb;
        }
        else {
            Variable::Magic::cast %^H, $wiz, $cb;
        }
    }
}


1;

__END__
#line 91

