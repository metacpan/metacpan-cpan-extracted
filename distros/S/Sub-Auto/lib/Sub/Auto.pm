package Sub::Auto;

our $VERSION = 0.0202;

=head1 NAME

Sub::Auto - declare individual handlers for AUTLOADed subs, respecting can and inheritance

=head1 SYNOPSIS

 use Sub::Auto;

 autosub /^get_(\w+)$/ {
    my ($what, @pars) = @_;
    print "Getting $what...\n";
 }

 autosub /^set_(\w+)_(\w+)$/ {
    my ($adjective, $noun, @pars) = @_;
    print "Setting the $adjective $noun\n";
 }

 autosub handle_foo_events /foo$/ {
    my ($subname, @pars) = @_;
    print "Called $subname to do something to a foo\n";
 }

 get_foo();
 if (__PACKAGE__->can('set_blue_cat')) { ... }

=head1 DESCRIPTION

C<AUTOLOAD>, like other languages' C<method-missing> features is a useful feature
for those situations when you want to handle sub or method calls dynamically, and
can't pre-generate the subroutines with accessor generators.

To be sure, this is almost never the case, but occasionally, C<AUTOLOAD> is convenient.

Well, "convenient" is a strong word, writing C<sub AUTOLOAD> handlers is mildly
unpleasant, and doesn't handle inheritance and C<can> by default.

Using C<Sub::Auto> you can:

=over 4

=item *

Declare multiple handlers, each responding to calls matching a given regular expression.

=item *

Optionally name your handler, for clarity, or because you want to call it directly.

=item *

Ensure that unhandled methods get dealt with by the next class in the inheritance chain.

=back

=head1 USAGE

=head2 C<autosub>

 autosub [name] /regex/ { ... }

If the regex contains capturing parentheses, then each of those items will be prepended
to the sub's argument list.  For example:

 autosub /(\w+)_(\w+)/ {
    my ($verb, $noun, @params) = @_;
    print "$verb'ing $noun - " . join ','=>@params;
 }

 jump_up('one', 'two'); # prints "jump'ing up - one,two"

If the matching regex didn't have any capturing parens, the entire method name
is passed as the first argument.

The name of the sub is optional.  It registers a normal subroutine or method with
that name in the current package.  Nothing will be automatically prepended to a call
to this method!

 autosub foo /(\w+)_(\w+)/ {
    my ($verb, $noun, $one,$two) = @_;
    print $one + $two;
 }

 foo (undef,undef, 1, 2);

=head1 SEE ALSO

L<Class::AutoloadCAN> by Ben Tilly, does all the heavy lifting.

L<Devel::Declare> by Matt Trout provides the tasty syntactic sugar.

L<http://greenokapi.net/blog/2008/07/03/more-perl-hate-and-what-to-do-about-it-autoload/>

L<Class::Accessor> or various other method generators that are a saner solution in general
than using AUTOLOAD at all.

=head1 AUTHOR AND LICENSE

 (c) 2008 osfameron@cpan.org

This module is released under the same terms as Perl itself.

=cut

use strict; use warnings;

use Class::AutoloadCAN;
use Devel::Declare 0.002;
use Sub::Name;
use Scope::Guard;
use vars qw($AUTOLOAD);

sub import {
    my $class = shift;
    my $caller = caller;

    my $parser = mk_parser($caller);
    Devel::Declare->setup_for( 
        $caller => { autosub => { const => $parser }} );

    no strict 'refs';
    *{$caller.'::autosub'} = sub (&) {};

    # trick via mst.   See also export_to_level and Sub::Exporter
    *{ "${caller}::CAN" } = mk_can($caller);
    goto &Class::AutoloadCAN::import;
}

sub mk_can {
    my $package = shift;


    return sub {
        my ($class, $method, $self, @arguments) = @_;
        # YUCK!
        no strict 'refs';
        no warnings 'once';
        for my $can (@{"${package}::CANS"}) {
            my ($re, $sub) = @$can;
            if (my @result = $method =~ /$re/) {
                @result = $method unless defined $1; # or $& ?
                return sub {
                    $sub->(@result, @_)
                    };
            }
        }
        return;
        };
}

# Following boilerplate is stolen from Devel::Declare's t/method-no-semi.t
# Note that, as with Sub::Curried and Method::Signatures, this boilerplate
# may well be made into the "official" API shortly, at which point we'll
# refactor and clean up!

{
    our ($Declarator, $Offset);

    sub skip_declarator;
    sub strip_name;
    sub strip_proto;

    sub mk_parser {
      my $package = shift;
      return sub {
        local ($Declarator, $Offset) = @_;
        skip_declarator;
        my $name = strip_name;
        my $re = strip_proto;

        if (defined $name) {
            $name = join('::', Devel::Declare::get_curstash_name(), $name)
              unless ($name =~ /::/);
        }

        # we do scope trick even if no name (as the proto is a kind of name)
        my $inject = scope_injector_call();
        inject_if_block($inject);

        no strict 'refs';
        my $installer = sub (&) {
            my $f = shift;
            # YUCK!
            push @{"${package}::CANS"}, [qr/$re/, $f];
            # if we have a name, then install
            if ($name) {
                no strict 'refs';
                *{$name} = subname $name => $f;
            }
            return $f;
            };
        shadow($installer);
      };
    }

    sub skip_declarator {
        $Offset += Devel::Declare::toke_move_past_token($Offset);
    }

    sub skipspace {
        $Offset += Devel::Declare::toke_skipspace($Offset);
    }

    sub strip_name {
        skipspace;
        if (my $len = Devel::Declare::toke_scan_word($Offset, 1)) {
            my $linestr = Devel::Declare::get_linestr();
            my $name = substr($linestr, $Offset, $len);
            substr($linestr, $Offset, $len) = '';
            Devel::Declare::set_linestr($linestr);
            return $name;
        }
        return;
    }

    sub strip_proto {
        skipspace;
    
        my $linestr = Devel::Declare::get_linestr();
        if (substr($linestr, $Offset, 1) =~/^[[:punct:]]$/ ) {
            my $length = Devel::Declare::toke_scan_str($Offset);
            my $proto = Devel::Declare::get_lex_stuff();
            Devel::Declare::clear_lex_stuff();
            $linestr = Devel::Declare::get_linestr();
            substr($linestr, $Offset, $length) = '';
            Devel::Declare::set_linestr($linestr);
            return $proto;
        }
        return;
    }

    sub shadow {
        my $pack = Devel::Declare::get_curstash_name;
        Devel::Declare::shadow_sub("${pack}::${Declarator}", $_[0]);
    }
    
    sub inject_if_block {
        my $inject = shift;
        skipspace;
        my $linestr = Devel::Declare::get_linestr;
        if (substr($linestr, $Offset, 1) eq '{') {
            substr($linestr, $Offset+1, 0) = $inject;
            Devel::Declare::set_linestr($linestr);
        }
    }

    # Set up the parser scoping hacks that allow us to omit the final
    # semicolon
    sub scope_injector_call {
        my $pkg = __PACKAGE__;
        return " BEGIN { ${pkg}::inject_scope }; ";
    }
    sub inject_scope {
        $^H |= 0x120000;
        $^H{DD_METHODHANDLERS} = Scope::Guard->new(sub {
            my $linestr = Devel::Declare::get_linestr;
            my $offset = Devel::Declare::get_linestr_offset;
            substr($linestr, $offset, 0) = ';';
            Devel::Declare::set_linestr($linestr);
        });
    }
}
    
1;
