use strict;
use warnings;
use Test::More tests => 1;
use Syntax::Highlight::Engine::Simple::Perl;
use utf8;
binmode(STDIN,	":utf8");
binmode(STDOUT,	":utf8");
binmode(STDERR,	":utf8");

my $highlighter = Syntax::Highlight::Engine::Simple::Perl->new();
my $expected = '';
my $result = '';

### ----------------------------------------------------------------------------
### 1. Define syntax
### ----------------------------------------------------------------------------
is( $highlighter->doStr(str => <<'ORIGINAL'), $expected=<<'EXPECTED' ); #01
### ----------------------------------------------------------------------------
### constractor
### ----------------------------------------------------------------------------
sub new {
    
    my $class = shift;
    my $self =
        bless {type => undef, syntax  => undef, @_}, $class;
    
    $self->setParams(@_);
    
    if ($self->{type}) {
            
        my $class = "Syntax::Highlight::Engine::Simple::". $self->{type};
        
        $class->require or croak $@;
        
        no strict 'refs';
        &{$class. "::setSyntax"}($self);
        
        return $self;
    }
    
    $self->setSyntax();
    
    return $self;
}
ORIGINAL
<span class='comment'>### ----------------------------------------------------------------------------</span>
<span class='comment'>### constractor</span>
<span class='comment'>### ----------------------------------------------------------------------------</span>
<span class='keyword'>sub</span> new {
    
    <span class='keyword'>my</span> <span class='variable'>$class</span> = <span class='keyword'>shift</span>;
    <span class='keyword'>my</span> <span class='variable'>$self</span> =
        <span class='keyword'>bless</span> {type =&gt; <span class='keyword'>undef</span>, syntax  =&gt; <span class='keyword'>undef</span>, <span class='variable'>@_</span>}, <span class='variable'>$class</span>;
    
    <span class='variable'>$self</span>-&gt;<span class='method'>setParams</span>(<span class='variable'>@_</span>);
    
    <span class='keyword'>if</span> (<span class='variable'>$self</span>-&gt;{type}) {
            
        <span class='keyword'>my</span> <span class='variable'>$class</span> = <span class='wquote'>"Syntax::Highlight::Engine::Simple::"</span>. <span class='variable'>$self</span>-&gt;{type};
        
        <span class='variable'>$class</span>-&gt;<span class='method'>require</span> or croak $@;
        
        <span class='keyword'>no</span> strict <span class='quote'>'refs'</span>;
        &amp;{<span class='variable'>$class</span>. <span class='wquote'>"::setSyntax"</span>}(<span class='variable'>$self</span>);
        
        <span class='keyword'>return</span> <span class='variable'>$self</span>;
    }
    
    <span class='variable'>$self</span>-&gt;<span class='method'>setSyntax</span>();
    
    <span class='keyword'>return</span> <span class='variable'>$self</span>;
}
EXPECTED
