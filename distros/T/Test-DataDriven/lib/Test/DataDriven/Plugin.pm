package Test::DataDriven::Plugin;

=head1 NAME

Test::DataDriven::Plugin - when Test::Base is not enough

=head1 SYNOPSIS

See C<Test::DataDriven>

=cut

use strict;
use warnings;

use Class::Spiffy -base;
use Test::DataDriven ();

our @EXPORT = qw(test_name);

my %attributes;
my %dispatch;

=head1 METHODS

=cut

sub MODIFY_CODE_ATTRIBUTES {
    my( $class, $code, @attrs ) = @_;
    my( @known, @unknown );

    foreach ( @attrs ) {
        /^(?:Begin|Run|End|Endc|Filter)\s*(?:$|\()/ ?
          push @known, $_ : push @unknown, $_;
    }

    $attributes{$class}{$code} = [ $code, \@known ];

    return @unknown;
}

our $test_name;

=head2 test_name

  my $test_name = test_name();

This function is exported by default. The test name is
"$block - $action - $section".b

=cut

sub test_name() { $test_name }

sub _parse {
    my( @attributes ) = @_;

    return map  { m/^(\w+)\(\s*(\w+)\s*\)/ or die $_;
                  [ lc( $1 ), $2 ]
                  }
                @attributes;
}

=head2 register

    __PACKAGE__->register;

This method must be called by every C<Test::DataDriven::Plugin>
subclass in order to register the section handlers with
C<Test::DataDriven>.

=cut

sub _apply_filter {
    my( $self, $filter, @value ) = @_;
    local $_;
    # cut'n'pasted from Test::Base (this sucks)
    $Test::Base::Filter::arguments =
      $filter =~ s/=(.*)$// ? $1 : undef;
    my $function = "main::$filter";
    no strict 'refs';
    if (defined &$function) {
        $_ = join '', @value;
        @value = &$function(@value);
        if (not(@value) or
            @value == 1 and $value[0] =~ /\A(\d+|)\z/
           ) {
            @value = ($_);
        }
    }
    else {
        my $filter_object = $self->blocks_object->filter_class->new;
        die "Can't find a function or method for '$filter' filter\n"
          unless $filter_object->can($filter);
        $filter_object->current_block($self);
        @value = $filter_object->$filter(@value);
    }

    return @value;
}

sub register {
    my( $self, $pluggable ) = @_;
    my $class = ref( $self ) || $self;
    my @attributes = values %{$attributes{$class}};
    my %keys;

    foreach my $attr ( @attributes ) {
        my( $sub, $attrs ) = @$attr;
        my @parsed = _parse @$attrs;
        # filter subroutines
        if( @parsed == 1 && $parsed[0][0] eq 'filter' ) {
            no strict 'refs';
            *{'main::' . $parsed[0][1]} = $sub;
            next;
        }
        # handle per-subroutine filters
        foreach my $h ( grep $_->[0] eq 'filter', reverse @parsed ) {
            my( $oldsub, $filter ) = ( $sub, $h->[1] );
            $sub = sub {
                my( $block, $section, @a ) = @_;
                @a = _apply_filter( $block, $filter, @a );
                &$oldsub( $block, $section, @a );
            };
        }
        # handle begin/run/end
        foreach my $h ( grep $_->[0] ne 'filter', @parsed ) {
            $keys{$h->[1]} = 1;
            push @{$dispatch{$class}{$h->[0]}{$h->[1]}}, $sub;
        }
    }

    $pluggable ||= 'Test::DataDriven';
    foreach my $key ( keys %keys ) {
        $pluggable->register( plugin => $self,
                              tag    => $key,
                              );
    }
}

sub _dispatch {
    my( $act, $self, $block, $section, @a ) = @_;
    my $class = ref( $self ) || $self;

    return unless    exists $dispatch{$class}
                  && exists $dispatch{$class}{$act}
                  && exists $dispatch{$class}{$act}{$section};

    local $Test::Builder::Level = 1;
    local $test_name = join ' - ', $block->name, $act, $section;

    my $run_one = 0;
    foreach my $sub ( @{$dispatch{$class}{$act}{$section}} ) {
        &$sub( $block, $section, @a );
        $run_one = 1;
    }

    return $run_one;
}

=head2 begin, run, end

Dispatch to the subroutines registered with attributes
C<Begin()>, C<Run()>, C<End()>, passing as parameters
the block object, section name and the section data.

=cut

sub begin { _dispatch( 'begin', @_ ); }
sub run { _dispatch( 'run', @_ ); }
sub end { _dispatch( 'end', @_ ); }

sub endc {
    my( $self, $block, $section, @v ) = @_;

    _dispatch( 'endc', @_ );
    _serialize_back( @_ );
}

my %started;

sub _serialize_back {
    my( $self, $block, $section, @v ) = @_;
    my $create_fh = Test::DataDriven->_create_fh;

    print $create_fh "=== ", $block->name, "\n" unless $started{$block};
    if( defined $block->description && $block->description ne $block->name ) {
        print $create_fh $block->description , "\n" ;
    }
    print $create_fh "--- ", $section;
    my $filters = $block->_section_map->{$section}{filters};
    if( $filters ) {
        print $create_fh ' ', $filters;
    }
    print $create_fh "\n";
    print $create_fh $block->original_values->{$section};

    $started{$block} = 1;
}

=head1 BUGS

Needs more documentation and examples.

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
