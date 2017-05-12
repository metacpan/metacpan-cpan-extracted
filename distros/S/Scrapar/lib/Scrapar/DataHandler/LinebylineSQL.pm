package Scrapar::DataHandler::LinebylineSQL;

use strict;
use warnings;
use base qw(Scrapar::DataHandler::_base);
use Scrapar::Util qw(zip);

sub _template {
    my $self = shift;
    my $data = shift;

    if (ref $self->{fields}) {
	my @k = @{$self->{fields}};

	return qq[INSERT INTO `Staging` (] . join(q[, ], @k) . qq[) ]
	    . qq[VALUES(]
	    . (join q/, /, 
	       map { qq['$_'] }
	       map { $data->{$_} =~ s[']['']g if $data->{$_}; $data->{$_} } @k)
	    . qq[);\n];
    }
    elsif (ref $self->{mapping}) {
	my @k = keys %{$self->{mapping}};

	return qq[INSERT INTO `Staging` (] . join(q[, ], map { $self->{mapping}{$_} } @k) 
	    . qq[) ]
	    . qq[VALUES(]
	    . (join q/, /, 
	       map { qq['$_'] }
	       map { $data->{$_} =~ s[']['']g if $data->{$_}; $data->{$_} } @k)
	    . qq[);\n];
    }
}

sub _record_exists {
    my $id = shift;

    my $sth = $ENV{SCRAPER_DBH}->prepare("SELECT ID FROM Staging WHERE ID = '$id';");
    $sth->execute;
    return $sth->rows;
}

sub _delete_record {
    my $id = shift;

    $ENV{SCRAPER_DBH}->do("DELETE FROM Staging WHERE ID = '$id'");
}

sub handle {
    my $self = shift;
    my $data = shift;

    if ($ENV{SCRAPER_COMMIT}) {
	for my $d (@{$data}) {
	    _delete_record $d->{ID} if _record_exists $d->{ID};
	    $ENV{SCRAPER_DBH}->do($self->_template($d));
	}
    }
    else {
	for my $d (@{$data}) {
	    print $self->_template($d);
	}
    }
}

1;

__END__

=pod

=head1 NAME

Scrapar::DataHandler::LinebylineSQL - Generates lines of SQL inserts to STDOUT

=head1 COPYRIGHT

Copyright 2009 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
