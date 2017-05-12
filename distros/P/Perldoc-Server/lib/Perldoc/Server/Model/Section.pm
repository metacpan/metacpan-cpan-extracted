package Perldoc::Server::Model::Section;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Model';

use Memoize;
memoize('pages', NORMALIZER => sub { $_[1] });

our @section_data = (
  { 
    id    => 'overview',
    name  => 'Overview',
    pages => [qw/perl perlintro perlrun perlbook perlcommunity/] 
  },
  {
    id    => 'tutorials',
    name  => 'Tutorials',
    pages => [qw/perlreftut perldsc perllol perlrequick 
                 perlretut perlboot perltoot perltooc perlbot
                 perlstyle perlcheat perltrap perldebtut
                 perlopentut perlpacktut perlthrtut perlothrtut
                 perlxstut perlunitut perlpragma/]
  },
  {
    id    => 'language',
    name  => 'Language reference',
    pages => [qw/perlsyn perldata perlsub perlop
                 perlfunc perlpod perlpodspec perldiag
                 perllexwarn perldebug perlvar perlre perlrecharclass perlrebackslash
                 perlreref perlref perlform perlobj perltie
                 perldbmfilter perlipc perlfork perlnumber
                 perlport perllocale perluniintro perlunicode
                 perlebcdic perlsec perlmod perlmodlib
                 perlmodstyle perlmodinstall perlnewmod
                 perlcompile perlfilter perlglossary CORE
                 /]
  },
  {
    id    => 'internals',
    name  => 'Internals and C language interface',
    pages => [qw/perlembed perldebguts perlxs perlxstut
                 perlclib perlguts perlcall perlapi perlintern
                 perliol perlapio perlhack perlreguts perlreapi/]
  },
  {
    id    => 'licence',
    name  => 'Licence',
    pages => [qw/perlartistic perlgpl/]
  },
  {
    id    => 'platforms',
    name  => 'Platform specific',
    pages => [qw/perlaix perlamiga perlapollo perlbeos perlbs2000
                 perlce perlcygwin perldgux perldos perlepoc
                 perlfreebsd perlhpux perlhurd perlirix perllinux
                 perlmachten perlmacos perlmacosx perlmint perlmpeix
                 perlnetware perlopenbsd perlos2 perlos390 perlos400
                 perlplan9 perlqnx perlriscos perlsolaris perlsymbian perltru64 perluts
                 perlvmesa perlvms perlvos perlwin32/]
  },
#  { 
#    id        => 'pragmas',
#    name      => 'Pragmas',
#    pages     => [qw/attributes attrs autouse base bigint bignum 
#                     bigrat blib bytes charnames constant diagnostics
#                     encoding feature fields filetest if integer less lib
#                     locale mro open ops overload re sigtrap sort strict
#                     subs threads threads::shared utf8 vars vmsish
#                     warnings warnings::register/]
#  },
  {
    id        => 'utilities',
    name      => 'Utilities',
    pages     => [qw/perlutil a2p c2ph config_data corelist cpan cpanp
                     cpan2dist dprofpp enc2xs find2perl h2ph h2xs instmodsh
                     libnetcfg perlbug perlcc piconv prove psed podchecker
                     perldoc perlivp pod2html pod2latex pod2man pod2text
                     pod2usage podselect pstruct ptar ptardiff s2p shasum
                     splain xsubpp perlthanks/]
  },
  {
    id        => 'faq',
    name      => 'FAQs',
    lastpages => [qw/perlunifaq/],
    pagematch => qr/^perlfaq/,
    sort      => sub {$a cmp $b}
  },
  { 
    id        => 'history',
    name      => 'History / Changes',
    pages     => [qw/perlhist perltodo perldelta/],
    pagematch => qr/^perl\d+delta$/,
    sort      => sub {
                   (my $c = $a) =~ s/.*?(\d)(\d+).*/$1.$2/;
                   (my $d = $b) =~ s/.*?(\d)(\d+).*/$1.$2/;
                   $d <=> $c
                 }
  },
);


sub ACCEPT_CONTEXT { 
  my ( $self, $c, @extra_arguments ) = @_; 
  bless { %$self, c => $c }, ref($self); 
}


sub list {
  my $self = shift;
  
  return map {$_->{id}} @section_data;
}


sub name {
  my ($self,$section_id) = @_;
  
  return (map {$_->{name}} (grep {$_->{id} eq $section_id} @section_data))[0];
}


sub pages {
  my ($self, $section_id) = @_;
  
 foreach my $section (@section_data) {
    next unless ($section->{id} eq $section_id);
    my @pages;
    
    if ($section->{pages}) {
      push @pages,@{$section->{pages}};
    }
    
    if ($section->{pagematch}) {
      my @matched_pages = grep {$_ =~ $section->{pagematch}} $self->{c}->model('Index')->find_modules;
      if (my $sortsub = $section->{sort}) {
        @matched_pages = sort $sortsub @matched_pages;
      }
      push @pages, @matched_pages;
    }
    
    if ($section->{lastpages}) {
      push @pages,@{$section->{lastpages}};
    }
    
    return @pages;
  }
}


sub exists {
  my ($self, $section_id) = @_;
  
  foreach my $section (@section_data) {
    return 1 if ($section->{id} eq $section_id);
  }
  
  return undef;
}

=head1 NAME

Perldoc::Server::Model::Section - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
