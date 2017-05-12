
# package for compatilibity with older Tangram APIs.

# first major change: Tangram::Scalar => Tangram::Type::Scalar, etc

package Tangram::Compat;

use Set::Object qw(refaddr set);

use Tangram::Compat::Stub;

use constant REMAPPED =>
    qw( Tangram::Scalar			Tangram::Type::Scalar

	Tangram::String			Tangram::Type::String
	Tangram::Integer		Tangram::Type::Integer
	Tangram::Real			Tangram::Type::Real
	Tangram::Number			Tangram::Type::Number

	Tangram::RawTime		Tangram::Type::Time
	Tangram::RawDate		Tangram::Type::Date
	Tangram::RawDateTime		Tangram::Type::TimeAndDate

	Tangram::CookedDateTime		Tangram::Type::Date::Cooked
	Tangram::DMDateTime		Tangram::Type::Date::Manip
	Tangram::TimePiece		Tangram::Type::Date::TimePiece
	Tangram::DateTime		Tangram::Type::Date::DateTime

	Tangram::Coll			Tangram::Type::Abstract::Coll
	Tangram::AbstractSet		Tangram::Type::Abstract::Set
	Tangram::AbstractHash		Tangram::Type::Abstract::Hash
	Tangram::AbstractArray		Tangram::Type::Abstract::Array

	Tangram::Set			Tangram::Type::Set::FromMany
	Tangram::Hash			Tangram::Type::Hash::FromMany
	Tangram::Array			Tangram::Type::Array::FromMany
	Tangram::Ref			Tangram::Type::Ref::FromMany

	Tangram::IntrSet		Tangram::Type::Set::FromOne
	Tangram::IntrHash		Tangram::Type::Hash::FromOne
	Tangram::IntrArray		Tangram::Type::Array::FromOne
	Tangram::IntrRef		Tangram::Type::Ref::FromOne

	Tangram::BackRef		Tangram::Type::BackRef

	Tangram::FlatHash		Tangram::Type::Hash::Scalar
	Tangram::FlatArray		Tangram::Type::Array::Scalar

	Tangram::Alias			Tangram::Expr::TableAlias
	Tangram::CollCursor		Tangram::Cursor::Coll

        Tangram::Dump			Tangram::Type::Dump
        Tangram::IDBIF			Tangram::Type::Dump::Any
        Tangram::PerlDump		Tangram::Type::Dump::Perl
        Tangram::Storable		Tangram::Type::Dump::Storable
        Tangram::YAML			Tangram::Type::Dump::YAML

	Tangram::Filter                 Tangram::Expr::Filter
	Tangram::CursorObject           Tangram::Expr::CursorObject
	Tangram::QueryObject		Tangram::Expr::QueryObject
	Tangram::RDBObject		Tangram::Expr::RDBObject
	Tangram::Select			Tangram::Expr::Select
	Tangram::Table			Tangram::Expr::Table

	Tangram::Oracle                 Tangram::Driver::Oracle
	Tangram::mysql                  Tangram::Driver::mysql
	Tangram::Pg                     Tangram::Driver::Pg
	Tangram::SQLite                 Tangram::Driver::SQLite
	Tangram::SQLite2                Tangram::Driver::SQLite2
	Tangram::Sybase                 Tangram::Driver::Sybase

      );

use strict 'vars', 'subs';
use Carp qw(cluck confess croak carp);

sub DEBUG() { 0 }
sub debug_out { print STDERR __PACKAGE__.": @_\n" }

our $stub;
BEGIN { $stub = $INC{'Tangram/Compat/Stub.pm'} };

# this method is called when you "use" something.  This is a "Chain of
# Command Patte<ETOOMUCHBS>

our $PKG_NOWARN = set();
sub quiet {
    my $pkg = shift;
    #print SDTERR "$pkg is quiet\n";
    $PKG_NOWARN->insert($pkg);
}

sub Tangram::Compat::INC {
    my $self = shift;
    my $fn = shift;

    (my $pkg = $fn) =~ s{/}{::}g;
    $pkg =~ s{.pm$}{};

    (DEBUG) && debug_out "saw include for $pkg";

    if (exists $self->{map}->{$pkg}) {
	$self->setup($pkg);
	open DEVNULL, "<$stub" or die $!;
	return \*DEVNULL;
    }
    else {
	return undef;
    }
}

sub setup {
    debug_out("setup(@_)") if (DEBUG);
    my $self = shift;
    my $pkg = shift or confess ("no pkg!");
    undef &{"${pkg}::AUTOLOAD"};
    my $target = $self->{map}{$pkg} or return;

    my @c = caller();
    my $n;
    while ( $c[0] and $c[0] =~ m/^(Tangram::Compat|base)/ ) {
	@c = caller(++$n);
    }
    @c = caller($n-1) unless @c;
    carp("deprecated package $pkg used by $c[0] ($c[1]:$c[2]); "
	."auto-loading $target")
	if $^W and !$PKG_NOWARN->includes($c[0]);

    debug_out("using $target") if (DEBUG);
    #kill 2, $$;
    eval "use $target";
    #kill 2, $$;
    debug_out("using $target yielded \$\@ = '$@'") if DEBUG;
    die $@ if $@;
    @{"${pkg}::ISA"} = $target;
    #debug_out("creating package yielded \$\@ = '$@'") if DEBUG;
    if ( @_ ) {
	my $method = shift;
	($pkg, $method) = $method =~ m{(.*)::(.*)};
	@_ = @{(shift)};
	my $code = $pkg->can($method)
	    or do {
		debug_out("pkg is $pkg, its ISA is ".join(",",@{"${pkg}::ISA"})) if (DEBUG);
		croak "$pkg->can't($method)";
	    };
	debug_out("Calling $pkg->$method(@_)") if DEBUG;
	goto $code;
    }
}

our $AUTOLOAD;

sub new {
    my $inv = shift;
    my $self = bless { map => { @_ },
		     }, (ref $inv||$inv);
    for my $pkg ( keys %{$self->{map}} ) {
	debug_out "setting up $pkg => $self->{map}{$pkg}" if DEBUG;

	*{"${pkg}::AUTOLOAD"} = sub {
	    return if $AUTOLOAD =~ /::DESTROY$/;
	    debug_out "pkg is $pkg, AUTOLOAD is $AUTOLOAD" if DEBUG;
	    my $stack = [ @_ ];
	    @_ = ($self, $pkg, $AUTOLOAD, $stack);
	    goto &setup;
	};
    }
    return $self;
}

sub DESTROY {
    my $self = shift;
    @INC = grep { defined and 
		      (!ref($_) or refaddr($_) ne refaddr($self)) }
	@INC;
}

#use Devel::Symdump;
BEGIN {
    my $loader = __PACKAGE__->new(REMAPPED);
    #unshift @INC, __PACKAGE__->new( REMAPPED );
    #print STDERR "INC is now: @INC\n";
    #my $sd = Devel::Symdump->new("Tangram::Compat");
    #print STDERR "Compat is: ".$sd->as_string;
    unshift @INC, $loader;
}

1;
