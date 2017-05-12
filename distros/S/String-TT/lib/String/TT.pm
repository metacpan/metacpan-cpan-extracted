package String::TT;
use strict;
use warnings;
use PadWalker qw(peek_my);
use Carp qw(confess croak);
use Template;
use List::Util qw(min);
use Sub::Exporter -setup => {
    exports => [qw/tt strip/],
};

our $VERSION   = '0.03';
our $AUTHORITY = 'CPAN:JROCKWAY';

my %SIGIL_MAP = (
    '$' => 's',
    '@' => 'a',
    '%' => 'h',
    '&' => 'c', # probably do not need
    '*' => 'g', # probably do not need
);

{
    my $engine; 
    sub _build_tt_engine {
        return $engine ||= Template->new;
    }
}

sub tt($) {
    my $template = shift;
    confess 'Whoa there, I need a template' if !defined $template;

    my %vars = %{peek_my(1)||{}};
    my %transformed_vars;
    for my $v (keys %vars){
        my ($sigil, $varname) = ($v =~ /^(.)(.+)$/);
        my $suffix = $SIGIL_MAP{$sigil};
        my $name = join '_', $varname, $suffix;
        $transformed_vars{$name} = $vars{$v};
        if($sigil eq '$'){
            $transformed_vars{$name} = ${$transformed_vars{$name}};
        }
    }

    # add the plain scalar variables (without overwriting anything)
    for my $v (grep { /_s$/ } keys %transformed_vars) {
        my ($varname) = ($v =~ /^(.+)_s$/);
        if(!exists $transformed_vars{$varname}){
            $transformed_vars{$varname} = $transformed_vars{$v};
        }
    }

    my $t = _build_tt_engine;
    my $output;
    $t->process(\$template, \%transformed_vars, \$output)
        || croak $t->error;
    return $output;
}

sub strip($){
    my $lines = shift;

    my $trailing_newline = ($lines =~ /\n$/s);# perl silently throws away data
    my @lines = split "\n", $lines;
    shift @lines if $lines[0] eq ''; # strip empty leading line

    # determine indentation level
    my @spaces = map { /^(\040+)/ and length $1 or 0 } grep { !/^\s*$/ } @lines;
    
    my $indentation_level = min(@spaces);
    
    # strip off $indentation_level spaces
    my $stripped = join "\n", map { 
        my $copy = $_;
        substr($copy,0,$indentation_level) = "";
        $copy;
    } @lines;
    
    $stripped .= "\n" if $trailing_newline;
    return $stripped;
}

1;
__END__

=head1 NAME

String::TT - use TT to interpolate lexical variables

=head1 SYNOPSIS

  use String::TT qw/tt strip/;

  sub foo {
     my $self = shift;
     return tt 'my name is [% self.name %]!';
  }

  sub bar {
     my @args = @_;
     return strip tt q{
        Args: [% args_a.join(",") %]
     }
  }

=head1 DESCRIPTION

String::TT exports a C<tt> function, which takes a TT
(L<Template|Template> Toolkit) template as its argument.  It uses the
current lexical scope to resolve variable references.  So if you say:

  my $foo = 42;
  my $bar = 24;

  tt '[% foo %] <-> [% bar %]';

the result will be C<< 42 <-> 24 >>.

TT provides a slightly less rich namespace for variables than perl, so
we have to do some mapping.  Arrays are always translated from
C<@array> to C<array_a> and hashes are always translated from C<%hash>
to C<hash_h>.  Scalars are special and retain their original name, but
they also get a C<scalar_s> alias.  Here's an example:

  my $scalar = 'scalar';
  my @array  = qw/array goes here/;
  my %hash   = ( hashes => 'are fun' );

  tt '[% scalar %] [% scalar_s %] [% array_a %] [% hash_h %]';

There is one special case, and that's when you have a scalar that is
named like an existing array or hash's alias:

  my $foo_a = 'foo_a';
  my @foo   = qw/foo array/;

  tt '[% foo_a %] [% foo_a_s %]'; # foo_a is the array, foo_a_s is the scalar

In this case, the C<foo_a> accessor for the C<foo_a> scalar will not
be generated.  You will have to access it via C<foo_a_s>.  If you
delete the array, though, then C<foo_a> will refer to the scalar.

This is a very cornery case that you should never encounter unless you
are weird.  99% of the time you will just use the variable name.

=head1 EXPORT

None by default, but C<strip> and C<tt> are available.

=head1 FUNCTIONS

=head2 tt $template

Treats C<$template> as a Template Toolkit template, populated with variables
from the current lexical scope.

=head2 strip $text

Removes a leading empty line and common leading spaces on each line.
For example,

  strip q{
    This is a test.
     This is indented.
  };

Will yield the string C<"This is a test\n This is indented.\n">.

This feature is designed to be used like:

  my $data = strip tt q{
      This is a [% template %].
      It is easy to read.
  };

Instead of the ugly heredoc equivalent:

  my $data = tt <<'EOTT';
This is a [% template %].
It looks like crap.
EOTT


=head1 HACKING

If you want to pass args to the TT engine, override the
C<_build_tt_engine> function:

  local *String::TT::_build_tt_engine = sub { return Template->new( ... ) }
  tt 'this uses my engine';

=head1 VERSION CONTROL

This module is hosted in the C<jrock.us> git repository.  You can view
the history in your web browser at:

L<http://git.jrock.us/?p=String-TT.git;a=summary>

and you can clone the repository by running:

  git clone git://git.jrock.us/String-TT

Patches welcome.

=head1 AUTHOR

Jonathan Rockway C<< jrockway@cpan.org >>

=head1 COPYRIGHT

This module is copyright (c) 2008 Infinity Interactive.  You may
redistribute it under the same terms as Perl itself.
