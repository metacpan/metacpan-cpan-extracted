package Pcore::DBH::DDL::ChangeSet;

use Pcore -class;

has id => ( is => 'ro', isa => PositiveOrZeroInt, required => 1 );
has component => ( is => 'ro', isa => Str, default => '__schema__' );
has sql => ( is => 'ro', isa => Str | CodeRef, required => 1 );
has transaction => ( is => 'ro', isa => Bool, default => 1 );

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH::DDL::ChangeSet

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
