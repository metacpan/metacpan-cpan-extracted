package
    SomePackage;

sub first {
    my ($self, $args) = @_;
    $args->{this}->{that}->{other} = 
        { abcd => 'goldfish',
          mno  => [qw/goldfish/],
          rdr  => { goldfish => 'poem' }
      };

}

sub second {
    my ($self, $args) = @_;
    # ... do stuff
}

sub my_method {
    my ($self, $args) = @_;
    $args->{this}->{that}->{other} = 
        { abcd => 'goldfish',
          mno  => [qw/goldfish/],
          rdr  => { goldfish => 'poem' }
      };
    if ($args->{thing}) {
    $args->{other}->{this}->{that} =  
        { logo => 'turtle',
               mno  => [qw/aardvark/],
          zxc  => { goldfish => 'goat' }
      };
    }
    elsif ($args->{that}) {
        $args->{this}->{that}->{other} = 
        { abcd => 'goldfish',
          mno  => [qw/goldfish/],
          rdr  => { goldfish => 'poem' }
      };
    }
    else {
    elsif ($args->{that}) {
        $args->{this}->{that}->{other} = 
        { abcd => 'goldfish',
          mno  => [qw/goldfish/],
          rdr  => { goldfish => 'poem' }
      };
    }
}

1;
