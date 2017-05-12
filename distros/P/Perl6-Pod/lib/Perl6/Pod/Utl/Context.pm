package Perl6::Pod::Utl::Context;
our $VERSION = '0.01';
use warnings;
use strict;
use Perl6::Pod::Directive::use;
use Perl6::Pod::Directive::config;
use Perl6::Pod::Directive::alias;
use Perl6::Pod::Block::comment;
use Perl6::Pod::Block::code;
use Perl6::Pod::Block::para;
use Perl6::Pod::Block::head;
use Perl6::Pod::Block::table;
use Perl6::Pod::Block::output;
use Perl6::Pod::Block::input;
use Perl6::Pod::Block::nested;
use Perl6::Pod::Block::item;
use Perl6::Pod::FormattingCode::A;
use Perl6::Pod::FormattingCode::C;
use Perl6::Pod::FormattingCode::D;
use Perl6::Pod::FormattingCode::K;
use Perl6::Pod::FormattingCode::M;
use Perl6::Pod::FormattingCode::L;
#use Perl6::Pod::FormattingCode::P;
use Perl6::Pod::FormattingCode::B;
use Perl6::Pod::FormattingCode::I;
use Perl6::Pod::FormattingCode::S;
use Perl6::Pod::FormattingCode::U;
use Perl6::Pod::FormattingCode::X;
use Perl6::Pod::FormattingCode::E;
use Perl6::Pod::FormattingCode::R;
use Perl6::Pod::FormattingCode::T;
use Perl6::Pod::FormattingCode::N;
use Perl6::Pod::FormattingCode::Z;

use Tie::UnionHash;
use Data::Dumper;
=pod
        use     => 'Perl6::Pod::Directive::use',
        comment => 'Perl6::Pod::Block::comment',
        'M<>'   => 'Perl6::Pod::FormattingCode::M',

        #        'P<>'   => 'Perl6::Pod::FormattingCode::P',
        'S<>' => 'Perl6::Pod::FormattingCode::S',
        'V<>' => 'Perl6::Pod::FormattingCode::C', #V like C
=cut

use constant {
    DEFAULT_USE => {
        'File' => '-',
        'config'=>'Perl6::Pod::Directive::config',
        code    => 'Perl6::Pod::Block::code',
        'para' => 'Perl6::Pod::Block::para',
        alias   => 'Perl6::Pod::Directive::alias',
        nested  => 'Perl6::Pod::Block::nested',
        output  => 'Perl6::Pod::Block::output',
        input   => 'Perl6::Pod::Block::input',
        item    => 'Perl6::Pod::Block::item',
        defn    => 'Perl6::Pod::Block::item',
        head    => 'Perl6::Pod::Block::head',
        table   => 'Perl6::Pod::Block::table',
        'A<>' => 'Perl6::Pod::FormattingCode::A',
        'B<>'   => 'Perl6::Pod::FormattingCode::B',
        'C<>'   => 'Perl6::Pod::FormattingCode::C',
        'D<>'   => 'Perl6::Pod::FormattingCode::D',
        'E<>' => 'Perl6::Pod::FormattingCode::E',
        'I<>'   => 'Perl6::Pod::FormattingCode::I',
        'K<>'   => 'Perl6::Pod::FormattingCode::K',
        'L<>'   => 'Perl6::Pod::FormattingCode::L',
        'N<>' => 'Perl6::Pod::FormattingCode::N',
        'R<>' => 'Perl6::Pod::FormattingCode::R',
        'T<>' => 'Perl6::Pod::FormattingCode::T',
        'U<>' => 'Perl6::Pod::FormattingCode::U',
        'V<>'   => 'Perl6::Pod::FormattingCode::C',
        'X<>'   => 'Perl6::Pod::FormattingCode::X',
        'Z<>' => 'Perl6::Pod::FormattingCode::Z',
        '*'    => 'Perl6::Pod::Block',
        '*<>'  => 'Perl6::Pod::FormattingCode',

#        use     => 'Perl6::Pod::Directive::use',
#        config  => 'Perl6::Pod::Directive::config',
#        comment => 'Perl6::Pod::Block::comment',
#        alias   => 'Perl6::Pod::Directive::alias',
#        code    => 'Perl6::Pod::Block::code',
#        para    => 'Perl6::Pod::Block::para',
#        table   => 'Perl6::Pod::Block::table',
#        output  => 'Perl6::Pod::Block::output',
#        input   => 'Perl6::Pod::Block::input',
#        nested  => 'Perl6::Pod::Block::nested',
#        item    => 'Perl6::Pod::Block::item',
#        defn    => 'Perl6::Pod::Block::item',
#        'C<>'   => 'Perl6::Pod::FormattingCode::C',
#        'D<>'   => 'Perl6::Pod::FormattingCode::D',
#        'K<>'   => 'Perl6::Pod::FormattingCode::K',
#        'M<>'   => 'Perl6::Pod::FormattingCode::M',
#        'L<>'   => 'Perl6::Pod::FormattingCode::L',
#        'B<>'   => 'Perl6::Pod::FormattingCode::B',
#        'I<>'   => 'Perl6::Pod::FormattingCode::I',
#        'X<>'   => 'Perl6::Pod::FormattingCode::X',

        #        'P<>'   => 'Perl6::Pod::FormattingCode::P',
#        'U<>' => 'Perl6::Pod::FormattingCode::U',
#        'E<>' => 'Perl6::Pod::FormattingCode::E',
#        'N<>' => 'Perl6::Pod::FormattingCode::N',
#        'A<>' => 'Perl6::Pod::FormattingCode::A',
#        'R<>' => 'Perl6::Pod::FormattingCode::R',
#        'S<>' => 'Perl6::Pod::FormattingCode::S',
#        'T<>' => 'Perl6::Pod::FormattingCode::T',
#        'V<>' => 'Perl6::Pod::FormattingCode::C', #V like C
#        'Z<>' => 'Perl6::Pod::FormattingCode::Z',

    }
};

=head2 new [ <parent context ref>]

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    #set default contexts
    my %args = (
        _usef       => {},
        _alias       => {},
        _use        => DEFAULT_USE,
        _config     => {},
        _encoding   => 'UTF-8',
        _custom     => {},
        _class_opts => {},
        _allow_context => {},
        @_
    );

    #create union hashes
    while ( my ( $key, $val ) = each %args ) {
        next unless ( ref($val) || ref($val) eq 'HASH' );
        my %new_map = ();
        tie %new_map, 'Tie::UnionHash', $val, {};
        $args{$key} = \%new_map;

    }
    my $self = bless( \%args, $class );
    return $self;
}

=head2 sub_context

create sub_context

=cut

sub sub_context {
    my $self = shift;
    return __PACKAGE__->new(%$self);
}

=head2  get_config block_name

Get options for B<block_name> in current context

    $context->get_config('item1');

return ref to config options for С<block_name>
( implement :like attr)

=cut

sub  get_config {
    #TODO check for infinity loop
    my $self = shift;
    my $class_name = shift || return {};
    my %class_config = %{ $self->config->{$class_name} ||  {} };
    if ( my $like = delete  $class_config{like} ) {
        my @likes  = ref($like) eq 'ARRAY' ? @$like : ($like);
        foreach my $lname (@likes) {
           %class_config =( %class_config, %{ $self->get_config($lname) } );
        }
    }
    \%class_config;
}

=head2 config

return ref to hash of pod options per blockname

=cut

sub config {
    return $_[0]->{_config};
}

=head2 usef

return ref to hash of plugin  per formatcode name

=cut

sub usef {
    return $_[0]->{_usef};
}

=head2 use

return ref to hash of perl module per blockname

=cut

sub use {
    return $_[0]->{_use};
}

=head2 custom

return ref to hash of user defined keys,vals

=cut

sub custom {
    return $_[0]->{_custom};
}

=head2 class_opts

return ref to hash of Class optioons to create loaded by use mods

=cut

sub class_opts {
    return $_[0]->{_class_opts};
}

=head2 set_use <module_name>, ':config_options'

=cut

sub set_use {
    my $self = shift;
    my ( $name, $opt ) = @_;

    #now cut block_name
    my ( $b1, @bn ) = @{ $self->_opt2array($opt) };
    my $key = $b1->{name};
    my $block_opt = join " " => map { $_->{pod} } @bn;
    $self->use->{$key} = $name;
    $self->{_use_init}->{$name} = $block_opt;
    return { $key => $block_opt };
}

=head2 encoding

return ref to hash of pod options per blockname

=cut

sub encoding {
    return $_[0]->{_encoding};
}


1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

