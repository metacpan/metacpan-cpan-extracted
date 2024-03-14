use strict; use warnings;

use CPAN::Meta;
use CPAN::Meta::Merge;
use Software::LicenseUtils 0.103014;
use Pod::Readme::Brief 1.003;

sub slurp { open my $fh, '<', $_[0] or die "Couldn't open $_[0] to read: $!\n"; local $/; readline $fh }
sub trimnl { s/\A\s*\n//, s/\s*\z/\n/ for @_; wantarray ? @_ : $_[-1] }
sub mkparentdirs {
	my @dir = do { my %seen; sort grep s!/[^/]+\z!! && !$seen{ $_ }++, my @copy = @_ };
	if ( @dir ) { mkparentdirs( @dir ); mkdir for @dir }
}

chdir $ARGV[0] or die "Cannot chdir to $ARGV[0]: $!\n";

my %file;

my $meta = CPAN::Meta->load_file( 'META.json' );

my $license = do {
	my @key = ( $meta->license, $meta->meta_spec_version );
	my ( $class, @ambiguous ) = Software::LicenseUtils->guess_license_from_meta_key( @key );
	die if @ambiguous or not $class;
	$class->new( $meta->custom( 'x_copyright' ) );
};

if ( my %meta_add = (
	( map +( resources => { license => [ $_ ] } ), $license->url || () ),
	( map +( x_spdx_expression => $_ ), $license->spdx_expression || () ),
) ) {
	my $merger = CPAN::Meta::Merge->new( default_version => 2 );
	$meta = CPAN::Meta->new( $merger->merge( $meta->as_struct, \%meta_add ) );
	$file{'META.json'} = $meta->as_string;
	$file{'META.yml'} = $meta->as_string( { version => '1.4' } );
}

$file{'LICENSE'} = trimnl $license->fulltext;

my ( $main_module ) = map { s!-!/!g; s!^!lib/! if -d 'lib'; -f "$_.pod" ? "$_.pod" : "$_.pm" } $meta->name;

for my $pod_file ( $main_module, 'lib/Plack/App/File/Precompressed.pm' ) {
	( $file{ $pod_file } = slurp $pod_file ) =~ s{(^=cut\s*\z)}{ join "\n", (
		"=head1 AUTHOR\n", trimnl( $meta->authors ),
		"=head1 COPYRIGHT AND LICENSE\n", trimnl( $license->notice ),
		"=cut\n",
	) }me;
}

die unless -e 'Makefile.PL';
$file{'README'} = Pod::Readme::Brief->new( $file{ $main_module } )->render( installer => 'eumm' );

my @manifest = split /\n/, slurp 'MANIFEST';
my %manifest = map /\A([^\s#]+)()/, @manifest;
$file{'MANIFEST'} = join "\n", @manifest, ( sort grep !exists $manifest{ $_ }, keys %file ), '';

mkparentdirs sort keys %file;
for my $fn ( sort keys %file ) {
	unlink $fn if -e $fn;
	open my $fh, '>', $fn or die "Couldn't open $fn to write: $!\n";
	print $fh $file{ $fn };
	close $fh or die "Couldn't close $fn after writing: $!\n";
}
