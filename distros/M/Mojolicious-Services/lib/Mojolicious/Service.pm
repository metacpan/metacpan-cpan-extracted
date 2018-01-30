package Mojolicious::Service;
use Mojo::Base -base;
use Carp 'croak';

has [qw/dbi models app c/];

sub model{
  my ($self, $name) = @_;
  
  # Check model existence
  croak qq{model "$name" is not yet created } unless($self->models && $self->models->{$name});
  
  # Get model
  return $self->models->{$name};
}

=encoding utf8


=head1 NAME

Mojolicious::Service - Mojolicious框架中所有Service的基类（具体的Service需要用户实现）!


=head1 SYNOPSIS

    use Mojolicious::Service
    my $service = Mojolicious::Service->new({
          dbi=>DBIx::Custom->new(),
          models=>{}
      });
      
    my $user->some_mothed(arg1,arg2,……);


=head1 DESCRIPTION

Mojolicious框架中所有Service的基类（具体的Service需要用户实现）!

=head1 ATTRIBUTES

=head2 dbi

dbi 是为service提供数据库操作接口的对象。


=head2 models

models 是为service提供数据模型操作接口的对象。


=head2 app

当前应用程序的引用，通常是Mojolicious对象。

=head2 c

当前控制器的引用，通常是Mojolicious::Controller子类的对象。


=head1 METHODS

=head2 model

根据model的名称从 models 属性中获取model。


=head1 AUTHOR

wfso, C<< <461663376@qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-Services at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Services>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Service


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Services>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Services>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Services>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Services/>

=back


=cut

1; # End of Mojolicious::Service
