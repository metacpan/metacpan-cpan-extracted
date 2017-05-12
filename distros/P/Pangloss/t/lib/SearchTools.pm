package SearchTools;

use base qw( CreateCollections );

sub create_search {
    my $class  = shift;
    my $search = new Pangloss::Search()
      ->categories( $class->create_categories() )
      ->concepts( $class->create_concepts() )
      ->languages( $class->create_languages() )
      ->terms( $class->create_terms() )
      ->users( $class->create_users() );
}

1;
