package Regexp::Box;

our $VERSION = '0.02';

our $DEBUG = 0;

use Data::Dumper;

use Carp;

use Regexp::Common;

use Class::Maker qw(:all);

class
{
#    isa => [qw()],

    public =>
    {
	string => [qw( name )],
    },

    private =>
    {
        array => [qw( sets )],

	hash => [qw( registry )],
    },

    default => 
    {
	_sets => [qw(std net bio db_mysql)],
    },
};

sub _preinit : method
{
    my $this = shift;

    foreach ( $this->_sets )
    {
	my $fu = "_add_".$_;

	die __PACKAGE__.": Set $_ is not known yet. You already added it?" unless $this->can( $fu );

	$this->$fu;
    }
}
		# USAGE for field values are qr// or  sub ( ID, FIELD, @_ ) { }
 		#
		#	where $_registry->{ID}->{FIELD}

sub exact : method
{ 
    my $this = shift;

    return '^'.$_[0].'$';
}
		
sub register : method
{
    my $this = shift;

    if( $DEBUG )
    {
	print "register: arguments\n";

	print Dumper \@_;
    }

    my $id = shift;

    my $exact = shift;
    
    my $regexp = shift;
    
    my $desc = shift;
    
    $id and $regexp and $desc and defined $exact or Carp::croak "usage error: register( ID, EXACT, REGEXP, DESC )";
    
    $this->_registry->{$id}->{exact} = $exact;

    $this->_registry->{$id}->{regexp} = $regexp;
    
    $this->_registry->{$id}->{desc} = $desc;
    
    $this->_registry->{$id}->{created} = [ caller ];
}

# request( 'domain', 'desc' ) - returns ->{domain}->{desc}
# request( 'domain', 'regexp' ) - returns ->{domain}->{regexp}
#
# alternativly a coderef will lead to execution and return result

sub request
{
    my $this = shift;

    if( $DEBUG )
    {
	print "request: arguments\n";

	print Dumper \@_;
    }
    
    my $id = shift;
    
    my $field = shift;
    
    if( exists $this->_registry->{$id} )
    {
	if( exists $this->_registry->{$id}->{$field} )
	{
	    my $x = $this->_registry->{$id}->{$field};

	    my $result = ref($x) eq 'CODE' ? $x->( @_ ) : $x;

	    Carp::croak sprintf "$id returned undef or empty for $field" unless $result;

	    if( $field eq 'regexp' && exists $this->_registry->{$id}->{exact} )
	    {
		return $this->exact( $result ) if $this->_registry->{$id}->{exact};
	    }

	    return $result;
	}
	
	Carp::croak sprintf "$id is not registered in Regexp::Box '%s'", $this->name;
    }
    
    Carp::croak sprintf "$id is not registered in Regexp::Box '%s'", $this->name;
}

sub requestable : method
{
    my $this = shift;


return sort keys %{ $this->_registry };
}

###############################################################

sub _add_std
{
    my $this = shift;

  $this->register( 'std/word', 0, qr/[^\s]+/, 'set of non-spaces' );

  $this->register( 'std/binary', 1, qr/[01]+/, 'arbitrary combination of 0 and 1' );
     
  $this->register( 'std/hex', 1, qr/[0-9a-fA-F]+/, 'hexadecimal string' );

  $this->register( 'std/int', 1, $Regexp::Box::RE{num}{int}, 'integer' );
     
  $this->register( 'std/real', 1, $Regexp::Box::RE{num}{real}, 'real' );
     
  $this->register( 'std/quoted', 1, $Regexp::Box::RE{quoted}, 'string enclosed by matching quoting characters' );
     
  $this->register( 'std/uri', 1, sub { $Regexp::Box::RE{URI}{HTTP}{ -scheme => $_[1] || 'HTTP' } }, sub { sprintf "an uri (default: %s)",  $_[1] || 'HTTP' } );
     
  $this->register( 'std/net', 1, sub { $Regexp::Box::RE{'net'}{ $_[1] || 'IPv4' } }, 'IP (V4, V6, MAC) network address' );
     
  $this->register( 'std/zip', 1, sub { $Regexp::Box::RE{zip}{ $_[1] || 'Germany' } }, sub { sprintf 'a zip %s code (default: german)', $_[1] || 'german' } );
     
  $this->register( 'std/domain', 0, $Regexp::Common::URI::RFC1035::domain, 'RFC1035 domain name' );
}

sub _add_net
{
    my $this = shift;

  $this->register( 'net/simple_email', 0, qr/(?:[^\@]*)\@(?:\w+)(?:\.\w+)+/, 'primitiv regexp for email' );
}

sub _add_bio
{
    my $this = shift;

  $this->register( 'bio/dna', 1, qr/[ATGC]+/, q{arbitrary set of A, T, G or C} );

  $this->register( 'bio/rna', 1, qr/[AUGC]+/, q{arbitrary set of A, U, G or C} );

  $this->register(

		   'bio/triplet', 

		   1,
		   
		   sub 
		   {
		       my $this = shift;
		       
		       my $type = lc( shift || 'dna' );
		       
		       Carp::croak __PACKAGE__." required parameter missing dna (default) or rna" unless defined $type;
		       
		       Carp::croak sprintf "%s triplet usage failure (dna or rna) only and not $_[1]", __PACKAGE__, $type unless $type =~ /^[rd]na$/;
		       
		       return $type eq 'dna' ? qr/[ATGC]{3,3}/ : qr/[AUGC]{3,3}/; 
		   },

                   sub { sprintf "a triplet string of %s", $_[1] || 'dna (default) or rna' }
  );
}

sub _add_db_mysql
{
    my $this = shift;

    $this->register( 'db/mysql/date', 1, qr/\d{4}-[01]\d-[0-3]\d/, 'a date as described in the mysql doc' );

    $this->register( 'db/mysql/datetime', 1, qr/\d{4}-[01]\d-[0-3]\d [0-2]\d:[0-6]\d:[0-6]\d/, 'a datetime as described in the mysql doc' );

    $this->register( 'db/mysql/timestamp',  1, qr/[1-2][9|0][7-9,0-3][0-7]-[01]\d-[0-3]\d [0-2]\d:[0-6]\d:[0-6]\d/, 'a timestamp as described in the mysql doc' );

    $this->register( 'db/mysql/time', 1, qr/-?\d{3,3}:[0-6]\d:[0-6]\d/, 'a time as described in the mysql doc' );
 
    $this->register( 'db/mysql/year4', 1, qr/[0-2][9,0,1]\d\d/, 'as described in the mysql doc' );

    $this->register( 'db/mysql/year2', 1, qr/\d{2,2}/, 'as described in the mysql doc' );

}

1;

=pod

=head1 NAME

Regexp::Box - store and retrieve regexp via names

=head1 SYNOPSIS

 $rebox = Regexp::Box->new( name => 'name of the box' );

 $rebox->register( 'category/id', 0, qr/\w/, 'description' );

 $rebox->register( 'category/id2', 0, 
   
   sub { '\w' x 3 }, 

   sub { sprintf 'description of %s', $_[0] } 

 );

 unless( $_ =~ $rebox->request( 'category/id', 'regexp' ) )
 {
   warn "Expected ", $rebox->request( 'category/id', 'desc' );
 }

=head1 DESCRIPTION

Store and retrieve regexp via names and serve them application wide. My favorite 
L<Regexp::Common> was somehow to complicated with that particular issue.

=head1 METHODS

=head3 $rebox = Regexp::Box->new( name => 'name of the box' )

Just give the box a name. Helps when multiple box's have to be handled.

=head3 $rebox->register( $id, $exact, $regexp, $desc )

Register a regexp. All arguments are required. The C<$id> should contain
a category path ( i.e. 'net/uri' ). It is used when later retrieved with
C<$rebox-E<gt>request>. The C<$exact> is a boolean field that defines if the
regexp gets wrapped with '^$' (see C<$rebox-E<gt>exact> below). One could
use closure/function-pointers as C<$regexp> or C<$desc> if some run-time
construction would be required (Some flexible L<Regexp::Common> regexp's require
that for argument passing. Here some examples:

 $rebox->register( 'category/id', 0, qr//, 'description' );

 $rebox->register( 'category/id', 0, sub { }, sub { 'description' } );

 $rebox->register(
 
   'std/uri', 

   1, 

   sub { $Regexp::Box::RE{URI}{HTTP}{ -scheme => $_[1] || 'HTTP' } }, 

   sub { sprintf "an uri (default: %s)",  $_[1] || 'HTTP' } 
 );

=head3 $field = $rebox->request( $id, $field_name )

Currently 'regexp', 'desc' and 'created', 'exact' as $field_name. 

 $rebox->request( 'net/email', 'desc' );

Returns the C<desc> field of the 'net/email' regexp.

=head3 @ids = $rebox->request();

Returns array of C<$id> of all registered regexps. 

=head3 $rebox->exact

Wraps a regex internally into '^$'. May be overloaded if its too stupid.

=head1 $Regexp::Box::RE

L<Regexp::Common> is heavily used and one could access it via C<$Regexp::Box::RE> without loading it redundantly.

=back

<& /maslib/delayed.mas, comp => '/maslib/signatures.mas:author_as_pod' &>

=cut
