package PDF::Collage;
use v5.24;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.001' }

use Carp;
use English                           qw< -no_match_vars >;
use JSON::PP                          qw< decode_json >;
use Data::Resolver                    qw< file_to_data generate >;
use PDF::Collage::Template            ();
use PDF::Collage::TemplatesCollection ();

use Exporter 'import';
our @EXPORT_OK = qw<
  collage
  collage_from_definition
  collage_from_dir
  collage_from_resolver
  collage_from_tar
>;
our %EXPORT_TAGS = (all => [@EXPORT_OK],);

sub collage ($input, @args) {
   my %args = @args == 0 ? (auto => $input) : ($input, @args);
   return collage_from_resolver($args{resolver})
     if defined $args{resolver};
   return collage_from_dir($args{dir}) if defined $args{dir};
   return collage_from_tar($args{tar}) if defined $args{tar};
   return collage_from_definition($args{definition})
     if defined $args{definition};
   if (defined(my $auto = $args{auto})) {
      my $ar = ref($auto);
      return collage_from_resolver($auto) if $ar eq 'CODE';

      if ($ar eq '' && $auto =~ m{\A [\[\{]}mxs) {
         $auto = decode_json($auto);
         $ar   = ref($auto);
      }
      return collage_from_definition($auto)
        if ($ar eq '' && $ar =~ m{\A \s* [\[\{] }mxs)
        || ($ar eq 'HASH')
        || ($ar eq 'ARRAY');

      croak "cannot handle auto input of type $ar" if $ar ne '';
      croak "cannot use provided automatic hint" unless -r $auto;

      return collage_from_dir($auto) if -d $auto;

      open my $fh, '<:raw', $auto or croak "open('$auto'): $OS_ERROR";
      my $first = '';
      my $n     = read $fh, $first, 1;
      croak "sysread() on '$auto': $OS_ERROR" unless defined $n;
      close $fh;
      return collage_from_definition(file_to_data($auto))
        if ($first eq '{') || ($first eq '{');
      return collage_from_tar($auto);
   } ## end if (defined(my $auto =...))

   croak 'no useful input';
} ## end sub collage

sub collage_from_definition ($def) {
   $def = decode_json($def) unless ref $def;
   $def = {commands => $def} if ref($def) eq 'ARRAY';
   return PDF::Collage::Template->new($def->%*);
}

sub collage_from_dir ($path, %args) {
   my $resolver = generate(
      {
         %args,
         root     => $path,
         -factory => 'resolver_from_dir',
      }
   );
   return collage_from_resolver($resolver);
} ## end sub collage_from_dir

sub collage_from_resolver ($resolver) {
   return PDF::Collage::TemplatesCollection->new(resolver => $resolver);
}

sub collage_from_tar ($path, %args) {
   my $resolver = generate(
      {
         %args,
         archive  => $path,
         -factory => 'resolver_from_tar',
      }
   );
   return collage_from_resolver($resolver);
} ## end sub collage_from_dir

1;
