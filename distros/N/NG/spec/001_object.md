面向对象
==============

基类 Object
----------------

    my $o = Object->new;
    $o->somemethod();
    $o->help();   # 自己的说明和所有方法说明
    $o->help("somemethod"); # 返回特定方法的说明
    print $o->dump();  # dump 自己的内容

类定义
-----------------

    def_class Animal => undef => ['sex', 'leg_color'] => {
        sound => sub {  .... },
        run => sub { .... },
    };

    def_class Dog => Animal => ['head_color'] => {
        eat => sub { ... },
        run => sub { ... },   # override method
    };

    my $x = Dog->new;
    $x->eat('bone');

以下所有类均继承自基类。

数组 Array
------------------

    my $ar = Array->new;
    $ar->push($value);
    print $ar->pop();
    $ar->unshift($value);
    print $ar->shift();
    print $ar->get($pos);
    print $ar->size();
    $ar->each(sub {
        my ($item, $pos) = @_;
    });
    $ar->remove($pos);
    $ar->sort(sub {
        my ($a, $b) = @_;
        return $a > $b;
    });
    

散列 Hashtable
-------------------

    my $h = Hashtable->new;
    $h->put("someproperty", $value);
    print $h->get("someproperty");
    my $keys = $h->keys();   # 返回的是 Array 的实例。
    my $values = $h->values();
    $h->each(sub {
        my($key, $value) = @_;
    });
    $h->remove($key);

有序散列 SHashtable
-----------------------

具有 Hashtable的所有功能，在 each 遍历的时候，会按照加入顺序遍历。



