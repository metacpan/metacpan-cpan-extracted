package PDFAPI2Mock;

BEGIN {

    # Mock PDF::API2

    # this is a mini MockObject with factory methods
    package Mock;
    sub new { return bless [] => shift; }

    sub get {
        my $self   = shift;
        my $method = shift;    # optional method name
        return $method ? grep( $_->[0] eq $method, @$self ) : @$self;
    }

    sub getall {
        my $self = shift;
        my @all;
        for (@$self) {
            push @all, ref( $_->[1] ) ? ( [ $_->[0] ], $_->[1]->getall ) : $_;
        }
        return @all;
    }

    sub match {
        my $self = shift;
        my $all = join( "\n", map { join( "\0", @$_ ) } $self->getall );
        for (@_) {
            my $patt = join( "\n", map { join( "\0", @$_ ) } @$_ );
            return 0 unless $all =~ /^$patt$/mcg;
        }
        return 1;
    }

    # class methods for creating object methods

    sub set_true {
        my $class = shift;

        for my $method (@_) {
            no strict 'refs';
            *{ $class . '::' . $method } =
              sub { push @{ +shift }, [ $method, @_ ]; return 1 };
        }
    }

    sub factory {
        my $class  = shift;
        my $target = shift;
        my $method = shift;

        no strict 'refs';
        *{ $class . '::' . $method } = sub {
            my $thing = $target->new;
            push @{ +shift }, [ $method, $thing ];
            return $thing;
        };
    }

    package PDF::API2;
    our @ISA = 'Mock';
    __PACKAGE__->set_true(qw(corefont));
    __PACKAGE__->factory( 'PDF::API2::Page', 'page' );

    package PDF::API2::Page;
    our @ISA = 'Mock';
    __PACKAGE__->factory( 'PDF::API2::Content',       'gfx' );
    __PACKAGE__->factory( 'PDF::API2::Content::Text', 'text' );

    package PDF::API2::Content;
    our @ISA = 'Mock';
    __PACKAGE__->set_true(
        qw(strokecolor linewidth move hline vline fillcolor stroke rect fill));
    package PDF::API2::Content::Text;
    our @ISA = 'Mock';
    __PACKAGE__->set_true(qw(font fillcolor translate text));
    sub advancewidth { shift; return 5 * length shift }
}
return 1;

