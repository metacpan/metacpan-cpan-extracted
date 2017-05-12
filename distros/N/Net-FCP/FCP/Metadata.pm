=head1 NAME

Net::FCP::Metadata - metadata utility class.

=head1 SYNOPSIS

 use Net::FCP::Metadata;

=head1 DESCRIPTION

=over 4

=cut

package Net::FCP::Metadata;

use Carp ();

use Net::FCP::Util qw(tolc touc xeh);

no warnings;

use overload
   '""' => sub { $_[0]->as_string };

=item $metadata = new Net::FCP::Metadata [$string_or_object]

Creates a new metadata Object from the given string or reference. The
object is overloaded and will stringify into the corresponding string form
(which might be slightly different than the string it was created from).

If no arguments is given, creates a new metadata object with just a
C<version> part.

The object is implemented as a hash reference. See C<parse_metadata>,
below, for info on it's structure.

=cut

sub new {
   my ($class, $data) = @_;

   $data = ref $data ? %$data
         : $data     ? parse_metadata ($data)
         :             { version => { revision => 1 } };

   bless $data, $class;
}

=item $metadata->as_string

Returns the string form of the metadata data.

=cut

sub as_string {
   build_metadata ($_[0]);
}

=item $metadata->add_redirect ($name, $target[ info1 => arg1...])

Add a simple redirection to the C<document> section to the given
target. All extra arguments will be added to the C<info> subsection and
often contains C<description> and C<format> fields.

=cut

sub add_redirect {
   my ($self, $name, $target, %info) = @_;

   push @{ $self->{document} }, {
      redirect => { target => $target },
      $name ? (name => $name) : (),
      %info ? (info => \%info) : (),
   };
}

=item $meta = Net::FCP::Metadata::parse_metadata $string

Internal utility function, do not use directly!

Parse a metadata string and return it.

The metadata will be a hashref with key C<version> (containing the
mandatory version header entries) and key C<raw> containing the original
metadata string.

All other headers are represented by arrayrefs (they can be repeated).

Since this description is confusing, here is a rather verbose example of a
parsed manifest:

   (
      raw => "Version...",
      version => { revision => 1 },
      document => [
                    {
                      info => { format" => "image/jpeg" },
                      name => "background.jpg",
                      redirect => { target => "freenet:CHK\@ZcagI,ra726bSw" },
                    },
                    {
                      info => { format" => "text/html" },
                      name => ".next",
                      redirect => { target => "freenet:SSK\@ilUPAgM/TFEE/3" },
                    },
                    {
                      info => { format" => "text/html" },
                      redirect => { target => "freenet:CHK\@8M8Po8ucwI,8xA" },
                    }
                  ]
   )

=cut

sub parse_metadata {
   my $data = shift;
   my $meta = { raw => $data };

   if ($data =~ /^Version\015?\012/gc) {
      my $hdr = $meta->{version} = {};

      for (;;) {
         while ($data =~ /\G([^=\015\012]+)=([^\015\012]*)\015?\012/gc) {
            my ($k, $v) = ($1, $2);
            my @p = split /\./, tolc $k, 3;

            $hdr->{$p[0]}               = $v if @p == 1; # lamest code I ever wrote
            $hdr->{$p[0]}{$p[1]}        = $v if @p == 2;
            $hdr->{$p[0]}{$p[1]}{$p[2]} = $v if @p == 3;
            die "FATAL: 4+ dot metadata"     if @p >= 4;
         }

         if ($data =~ /\GEndPart\015?\012/gc) {
            # nop
         } elsif ($data =~ /\GEnd(\015?\012|$)/gc) {
            last;
         } elsif ($data =~ /\G([A-Za-z0-9.\-]+)\015?\012/gcs) {
            push @{$meta->{tolc $1}}, $hdr = {};
         } elsif ($data =~ /\G(.*)/gcs) {
            print STDERR "metadata format error ($1), please report this string: <<$data>>";
            die "metadata format error";
         }
      }
   }

   #$meta->{tail} = substr $data, pos $data;

   $meta;
}

=item $string = Net::FCP::Metadata::build_metadata $meta

Internal utility function, do not use directly!

Takes a hash reference as returned by C<Net::FCP::parse_metadata> and
returns the corresponding string form. If a string is given, it's returned
as is.

=cut

sub build_metadata_subhash($$$) {
   my ($prefix, $level, $hash) = @_;

   join "",
      map
         ref $hash->{$_} ? build_metadata_subhash ($prefix . (Net::FCP::touc $_) . ".", $level + 1, $hash->{$_})
                         : $prefix . ($level > 1 ? $_ : Net::FCP::touc $_) . "=" . $hash->{$_} . "\n",
         keys %$hash;
}

sub build_metadata_hash($$) {
   my ($header, $hash) = @_;

   if (ref $hash eq ARRAY::) {
      join "", map build_metadata_hash ($header, $_), @$hash
   } else {
      (Net::FCP::touc $header) . "\n"
      . (build_metadata_subhash "", 0, $hash)
      . "EndPart\n";
   }
}

sub build_metadata($) {
   my ($meta) = @_;

   return $meta unless ref $meta;

   $meta = { %$meta };

   delete $meta->{raw};

   my $res =
      (build_metadata_hash version => delete $meta->{version})
      . (join "", map +(build_metadata_hash $_, $meta->{$_}), keys %$meta);

   substr $res, -5, 4, ""; # get rid of "Part". Broken Syntax....

   $res;
}

=back

=head1 SEE ALSO

L<Net::FCP>.

=head1 BUGS

Not heavily tested.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1;

