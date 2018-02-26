package Mojolicious::Plugin::Paging;
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Page;

our $VERSION = '0.1.2';

sub register{
  my ($self, $app, $conf) = @_;
  if(!Mojolicious::Controller->can('page')){
    Mojolicious::Controller->attr(page => sub{
        my $c = shift;
        my $v = $c->validation;
        
        ## 保存output以备后续恢复
        my $output = $v->output;
        $v->output({});
        
        $v->optional("page", "trim");
        $v->num;
        $v->optional("pre_page", "trim");
        $v->num;
        my $p = $v->output;
        
        ## 恢复output，解除分页功能对其他数据的影响
        $v->output($output);
        
        my $page = Mojolicious::Page->new(
          url => $c->url_with->to_string
        );
        if($p->{page}){
          $page->current_page($p->{page});
        }elsif($conf && $conf->{default_start_page}){
          $page->current_page($conf->{default_start_page});
        }
        if($p->{pre_page}){
          $page->pre_page_row($p->{pre_page});
        }elsif($conf && $conf->{default_pre_page}){
          $page->pre_page_row($conf->{default_pre_page});
        }
        return $page;
      }
    );
  }
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Paging - Mojolicious paging Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Paging');
  
  $self->plugin('Paging',{
    default_start_page => 1,
    default_pre_page => 10
  });

  # Mojolicious::Lite
  plugin 'Paging',{default_start_page => 1,default_pre_page => 10};

=head1 DESCRIPTION

L<Mojolicious::Plugin::Paging> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Paging> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
