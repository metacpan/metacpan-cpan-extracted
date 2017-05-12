package Sub::Parameters;
use strict;
use warnings;
use Hook::LexWrap;
use Devel::Caller qw(caller_cv called_with);
use Devel::LexAlias qw(lexalias);
use Carp qw(croak);
use Attribute::Handlers;

require Exporter;
use base 'Exporter';
our @EXPORT_OK = qw( Param );
our $VERSION = '0.03';

my @stack;

sub UNIVERSAL::WantParam : ATTR(CODE) {
    my ($symbol, $sub, $data) = @_[1, 2, 4];

    $data ||= 'positional';
    wrap $symbol,
      pre  => sub {
          my %order;
          if ($data eq 'named') {
              # prechew the ordering information
              for (my $i = 0; $i < $#_; $i += 2) {
                  $order{ $_[$i] } = $i + 1;
              }
          }
          push @stack, { data  => $data,
                         sub   => $sub,
                         order => \%order,
                         args  => \@_ };
      },
      post => sub { pop  @stack };
}


# you know, this would be a lot tidier if we could use ourselves
# already...

sub Param {
    local $Carp::CarpLevel = 3;
    _Parameter(caller_cv(1), called_with(0), called_with(0,1), $_[0]);
}

sub UNIVERSAL::Parameter : ATTR(VAR) {
    # 4 is a magic number dependant on Attribute::Handlers
    local $Carp::CarpLevel = 4;
    croak "your perl is not new enough to use the :Parameter form"
      if $] < 5.007002;

    my $sub = caller_cv($Carp::CarpLevel);
    my $referent = $_[2];

    require PadWalker;
    my %names = reverse %{ PadWalker::peek_sub( $sub ) };
    my $fullname = $names{$referent}
      or croak "couldn't find the name of $referent";

    ++$Carp::CarpLevel;
    _Parameter($sub, $referent, $fullname, $_[4]);
}

sub _Parameter {
    my ($sub, $referent, $fullname, $data) = @_;
    $data ||= 'copy';   # valid values: qw(copy rw)

    my $frame = $stack[-1];
    croak "attempt to use a Parameter in an undecorated subroutine"
      unless $frame->{sub} && $sub == $frame->{sub};

    my ($sigil, $name) = ($fullname =~ /^([\$@%])(.*)$/);

    # set the offset based on the scheme
    my $offset;
    if ($frame->{data} eq 'positional') {
        $offset = $frame->{index}++;
    }
    elsif ($frame->{data} eq 'named') {
        $offset = $frame->{order}{$name}
          or croak "can't find a parameter for '$sigil$name'";
    }
    else {
        croak "don't know what kind of processing to do!";
    }

    if ( $sigil eq '@' || $sigil eq '%' ) { # expect refs
        my $value = $frame->{args}[ $offset ];
        ref $value eq 'ARRAY' || croak "can't assign non-arrayref to '$sigil$name'"
          if $sigil eq '@';
        ref $value eq 'HASH'  || croak "can't assign non-hashref to '$sigil$name'"
          if $sigil eq '%';

        $value = (ref $value eq 'ARRAY' ? [ @$value ] : { %$value })
          if $data ne 'rw';

        lexalias($sub, $sigil.$name, $value);
        return;
    }

    # simple scalars
    if ($data eq 'rw') {
        lexalias($sub, $sigil.$name, \$frame->{args}[ $offset ]);
    }
    else {
        $$referent = $frame->{args}[ $offset ];
    }
}

1;
__END__

=head1 NAME

Sub::Parameters - enhanced parmeter handling

=head1 SYNOPSIS

 use Sub::Parameters;

 sub foo : WantParam {
     my $foo : Parameter;
     my $bar : Parameter(rw);

     $bar = 'foo';
     print "the foo parameter was '$foo'\n";
 }

 my $foo = 'bar';
 print "foo is '$foo';     # prints bar
 foo(1, $foo);
 print "foo is now '$foo'; # prints foo


=head1 DESCRIPTION

Sub::Parameters provides a syntactic sugar for parameter parsing.

It's primary interface is via attributes, you first apply notation to
the subroutine that you wish it to use extended parameter passing, and
of what style with the WantParams attribute.  You can then annotate
which lexicals within that subroutine are to be used to receive
parameters.

There are currently two styles of argument parsing supported
C<positional> and C<named>.

=head2 Positional parameters

With the C<positional> scheme parameters are assigned from @_ in the
same order as in the program text, as we see in the following example.

 sub example : WantParams(positional) {
     my $baz : Parameter;
     my $bar : Parameter;

     print $bar; # prints 'first value'
     print $baz; # prints 'second value'
 }

 example( 'first value', 'second value' );

Positional is the default scheme.


=head2 Named parameters

With the C<named> scheme parameters are assigned from @_ as though it
was an arguments hash, with the variable names as keys.

 sub demonstration : WantParams(named) {
     my $bar : Parameter;
     my $baz : Parameter;


     print $bar; # prints 'bar value'
     print $baz; # prints 'baz value'
 }

 demonstration( foo => 'foo value',
                baz => 'baz value',
                bar => 'bar value'  );


=head2 Readwrite parameters

Both positional and named parameters may be marked as readwrite (C<rw>
in the code.)  A readwrite parameter is passed by reference so
modifying the value within the subroutine modifies the original.

 sub specimen : WantParams {
     my $foo : Parameter(rw);

     print $foo; # prints 'foo value'
     $foo = "new value";
 }

 my $variable = "foo value";
 specimen( $variable );
 print $variable; # prints 'new value'


=head1 Alternate parameter syntax

For versions of perl older than 5.7.3 or 5.8.0 lexical attributes have
an implementation flaw.  In this case there is an alternative syntax
for identifying parameters:

 use Sub::Parameters 'Param';
 sub illustration: WantParams {
     Param( my $foo );
     Param( my $bar = 'rw' );
     ...
 }

=head1 TODO

=over

=item Think about positional @foo:Parameter slurp rather than @foo = [] semantics

=item think about methods

=back


=head1 SEE ALSO

C<Attribute::Handlers>, C<PadWalker>, C<Hook::LexWrap>, C<Devel::LexAlias>


=head1 AUTHOR

Richard Clamp E<lt>richardc@unixbeard.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2002, Richard Clamp. All Rights Reserved.  This module
is free software. It may be used, redistributed and/or modified under
the same terms as Perl itself.

=cut
