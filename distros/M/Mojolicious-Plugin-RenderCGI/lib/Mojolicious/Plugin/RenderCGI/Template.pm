package Mojolicious::Plugin::RenderCGI::Template;
use Mojo::Base -base;
use CGI;

my $CGI = CGI->new ;
#~ has _cgi => sub { CGI->new };
has [qw(_plugin _import _content)];# _content has coderef, 

sub new {
    my $self = shift->SUPER::new(@_);
    CGI->import(
      $self->_import && ref($self->_import) eq 'ARRAY'
        ? @{$self->_import}
        : (grep /\w/, split(/\s+/, $self->_import)),
      'escapeHTML',
      '-utf8',
    );
    return $self;
}


sub _compile {
  my $self = shift;
  my ($code) = @_;

  $self->_content(eval <<CODE);
sub {
  my (\$self, \$c, \$cgi) = \@_;
  undef, # может комменты придут без кода
  $code
}
CODE
  return $@
    if $@;
  return $self;
}

sub _run {
  my ($self, $c) = @_;
  
  $self->_content->($self, $c, $CGI);
}

sub esc { escapeHTML(@_) }

sub  AUTOLOAD {
  my ($package, $func) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  my $tag = $func =~ s/_/-/gr;
  my $package_arg = ref $_[0];
  no strict 'refs';
  no warnings 'redefine';
  
  if ($package eq $package_arg) { # method
    my $self = shift;
    #~ if ($CGI->can($func)) {
      #~ *{"${package}::$func"} = &_cgi_meth($func, 1);
    #~ } else { # HTML tag
      *{"${package}::$func"} = &_cgi_tag($tag, 1);
    #~ }
    
    return $self->$func(@_);
  }
   
  # non method
  #~ if ($CGI->can($func)) {
    #~ *$func = &_cgi_meth($func); #sub { $CGI->$func(@_); };
  #~ } else {
    *$func = &_cgi_tag($tag); # sub { return &CGI::_tag_func($tag,@_); };
  #~ }
  return &$func(@_);
  
}

sub _cgi_method {
  my $method = shift;
  my $flag_self = shift;
  return sub { my $self = shift if $flag_self; $CGI->$method(@_); };
}


sub _cgi_tag {
  my $tag = shift;
  my $flag_self = shift;
  return sub { my $self = shift if $flag_self; &CGI::_tag_func($tag,@_); };
}

=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::RenderCGI::Template

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::RenderCGI::Template - Package for cgi-handle templates. Normally internal only using from plugin.

=head1 SYNOPSIS

  $template = Mojolicious::Plugin::RenderCGI::Template->new(...);
  my $err = $template->_compile($content);
  unless (ref $err) {...} # compile error
  my @out = eval { $template->_run($c)};
  if ($@) {...} # runtime error
  $$output = join "\n", grep defined, @out;
  

=head1 ATRIBUTES (has)

All atributes has hidden names because you can generate any tags.

=head2 _plugin

=head2 _import

=head2 _content

=head1 METHODS

All methods has hidden names because you can generate any tags.

=head2 new

Each template is a seperate object.

=head2 _compile

Compile template content and store coderef inside atribute B<_content> and return error string if compile fails overwise self object.

=head2 _run

Simply execute compiled template coderef:

  $template->_content->($template, $c, $CGI);

=head2 AUTOLOAD

Will generate any tag trought CGI::_tag_func($tag,@_)

=cut

1;