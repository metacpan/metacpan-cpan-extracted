#!/usr/bin/perl 
use strict;
use warnings;
use lib qw( ../lib );
use Template::Perlish;

my $tp = Template::Perlish->new(
   variables => {
      director => 'PolettiX',
      locations =>
        [[city => qw( cars smog )], [country => qw( cow orkers )],]
   },
);

my $template = do { open my $fh, '<', 'example.tmpl'; local $/; <$fh> };

print {*STDOUT} <<'END_OF_CODE';
#!/usr/bin/env perl
use Getopt::Long qw( :config gnu_getopt );
use Storable qw( thaw fd_retrieve );
my %config;
GetOptions(
   \%config,
   'define|D=s@',
   'hdefine|hex-define|H|X=s@',
   'sdefine|storable-define|S=s@',
   'sstdin|storable-stdin|i!',
);
sub get_variables {
   my %variables;
   for my $dtype (qw( define hdefine sdefine )) {
      my $definitions = $config{$dtype};
      my $filter      = {
         define  => sub { shift },
         hdefine => sub { pack 'H*', shift },
         sdefine => sub { thaw pack 'H*', shift },
      }->{$dtype};
      for my $definition (@$definitions) {
         my ($name, $value) = split /=/, $definition, 2;
         $variables{$name} = defined $value ? $filter->($value) : 1;
      }
   } ## end for my $dtype (qw( define hdefine ddefine sdefine ))

   if (exists $config{sstdin}) {
      my $href = fd_retrieve(\*STDIN);
      while (my ($k, $v) = each %$href) {
         $variables{$k} = $v;
      }
   } ## end if (exists $config{sstdin...

   return %variables if wantarray;
   return \%variables;
} ## end sub get_variables

my %variables = get_variables();

END_OF_CODE

print {*STDOUT} $tp->compile($template);
