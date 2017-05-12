package Template::Plugin::LLHash;
use strict;

use base 'Template::Plugin';

our $VERSION = '0.01';

use Tie::LLHash;

sub new {
    my $class = shift;

    my %hash;

    tie (%hash, "Tie::LLHash", @_);

    my $self = {
        hash => \%hash,
    };

    bless $self, $class;
    return $self;

}


*insert_after = \&insert;
sub insert {
    my $self = shift;

    (tied %{$self->{hash}})->insert(@_);
}

sub insert_before {
    my $self = shift;


    my $find_name = (tied %{$self->{hash}})->key_before($_[2]);
    (tied %{$self->{hash}})->insert($_[0], $_[1],$find_name);

}



sub first {
    my $self = shift;

    (tied %{$self->{hash}})->first(@_);
}

sub last {
    my $self = shift;

    (tied %{$self->{hash}})->last(@_);

}

sub key_before {
    my $self = shift;

    (tied %{$self->{hash}})->key_before(@_);

}

sub key_after {
    my $self = shift;

    (tied %{$self->{hash}})->key_after(@_);
}

sub current_key {
    my $self = shift;

    (tied %{$self->{hash}})->key_after(@_);

}

sub current_value {
    my $self = shift;

    (tied %{$self->{hash}})->current_value(@_);

}

sub next {
    my $self = shift;

    (tied %{$self->{hash}})->next(@_);

}

sub prev {
    my $self = shift;

    (tied %{$self->{hash}})->prev(@_);

}

sub reset {
    my $self = shift;

    (tied %{$self->{hash}})->reset(@_);

}

sub keys {
    my $self = shift;

    keys %{$self->{hash}};
}

sub value_of {
    my $self = shift;

    $self->{hash}->{$_[0]};
}


*add = \&push;
*add_before = \&insert_before;
*add_after  = \&insert;
sub push {
    my $self = shift;

    return unless $_[0];

    (tied %{$self->{hash}})->last(@_);

    return;
}


sub unshift {
    my $self = shift;

    return unless $_[0];

    (tied %{$self->{hash}})->first(@_);

}


sub pop {
    my $self = shift;
    my $last = (tied %{$self->{hash}})->last();

    delete $self->{hash}->{$last};
}

sub delete {
    my $self = shift;

    delete $self->{hash}->{$_[0]};

}

1;
# The preceding line will help the module return a true value

__END__


=head1 NAME

Template::Plugin::LLHash - use Tie::LLHash with Template Toolkit

=head1 SYNOPSIS

  [% USE llhash  = Class.LLHash %]

  [% llhash.insert('first',1) %]

  [% llhash.last('last', 'four' ) %]

  [% llhash.insert('second', 'two', 'first' ) %]
  
  [% llhash.insert_before('third',3,'last') %]

  [% llhash.keys %]


=head1 DESCRIPTION

Use Tie::LLHash with Template Toolkit Templates.


=head1 OBJECT METHODS

=over 4

=item B<add($KEY, $VALUE)>


=item B<current_key>


=item B<current_value>


=item B<delete($KEY)>


=item B<first([$KEY,$VALUE])>


=item B<insert($KEY, $VALUE, [$INSERT_AFTER_KEY])>


=item B<insert_after($KEY, $VALUE, [$INSERT_BEFORE_KEY])>


=item B<insert_before($KEY, $VALUE, [$INSERT_BEFORE_KEY])>


=item B<key_before($KEY)>


=item B<key_after($KEY)>


=item B<keys>


=item B<last([$KEY,$VALUE])>


=item B<next>


=item B<prev>


=item B<pop>


=item B<push($KEY,$VALUE)>


=item B<reset>


=item B<unshift($KEY,$VALUE)>


=item B<value_of($KEY)>









=back


=head1 TODO

=over 4

A lot. Going to handle errors in a nicer Template type way.  Write more documentation, including an example of how I use this module to create the HEAD block for an HTML page.

=back



=head1 AUTHOR

    Kevin C. McGrath
    CPAN ID: KMCGRATH

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

