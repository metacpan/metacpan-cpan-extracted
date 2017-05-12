package Object::DeepCopy;
use Pony::Object;

    has ary => [];
    has struct =>{ group => { item1 => { foo => 'value',
                                         bar => 'value',
                                       },
                              item2 => { foo => 'value',
                                         bar => 'value',
                                       },
                              item3 => { foo => 'value',
                                         bar => 'value',
                                       },
                            },
                 };

1;

