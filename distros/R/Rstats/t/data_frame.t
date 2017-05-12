use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

# transform
{
  # transform - less elements
  {
    my $sex = c_('F', 'M', 'F', 'M');
    my $height = c_(172, 163, 155, 222);
    my $weight = c_(5, 6, 7, 8);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = r->transform($x1, sex => c_("P"));
    is_deeply(r->names($x2)->values, [qw/sex height weight/]);
    is_deeply($x2->getin(1)->values, ["P", "P", "P", "P"]);
  }
  
  # transform - basic
  {
    my $sex = c_('F', 'M', 'F', 'M');
    my $height = c_(172, 163, 155, 222);
    my $weight = c_(5, 6, 7, 8);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = r->transform($x1, sex => c_("P", "Q", "P", "Q"), new1 => c_(1, 2, 3, 4));
    is_deeply(r->names($x2)->values, [qw/sex height weight new1/]);
    is_deeply($x2->getin(1)->values, ["P", "Q", "P", "Q"]);
    is_deeply($x2->getin(4)->values, [1, 2, 3, 4]);
  }
}

# get
{
  
  # get - multiple elements
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(c_(1,3));
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['sex', 'weight']);
    my $tmp = r->dimnames($x2);
    is_deeply($tmp->getin(2)->values, ['sex', 'weight']);
  }

  # get - minus row index
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(c_(-1, -3), NULL);
    ok(r->is->data_frame($x2));
    is_deeply($x2->getin(1)->values, [qw/2/]);
    is_deeply($x2->getin(2)->values, [qw/168/]);
    is_deeply($x2->getin(3)->values, [qw/6/]);
  }
  
  # get - minus collum index
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(NULL, c_(-1, -3));
    ok(r->is->data_frame($x2));
    is_deeply(r->names($x2)->values, ['height']);
    is_deeply($x2->getin(1)->values, [qw/172 168 155/]);
  }
  
  # get - row index and column index is null
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(c_(3, 2), NULL);
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['sex', 'height', 'weight']);
    is_deeply(r->rownames($x2)->values, [qw/1 2/]);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/F M/]);
    is_deeply($x2->getin(2)->values, [qw/155 168/]);
    is_deeply($x2->getin(3)->values, [qw/7 6/]);
  }
  
  # get - row index and column index is null
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(c_(3, 2), NULL);
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['sex', 'height', 'weight']);
    is_deeply(r->rownames($x2)->values, [qw/1 2/]);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/F M/]);
    is_deeply($x2->getin(2)->values, [qw/155 168/]);
    is_deeply($x2->getin(3)->values, [qw/7 6/]);
  }
  
  # get - row index and column index
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(c_(3, 2), c_(1, 3));
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['sex', 'weight']);
    is_deeply(r->rownames($x2)->values, [qw/1 2/]);
    is_deeply(r->colnames($x2)->values, ['sex', 'weight']);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/F M/]);
    is_deeply($x2->getin(2)->values, [qw/7 6/]);
  }
  
  # get - logical, logical
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(c_(T_, F_, T_), c_(T_, F_, T_));
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['sex', 'weight']);
    is_deeply(r->rownames($x2)->values, [qw/1 2/]);
    is_deeply(r->colnames($x2)->values, ['sex', 'weight']);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/F F/]);
    is_deeply($x2->getin(2)->values, [qw/5 7/]);
  }
  
  # get - logical
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(c_(T_, F_, T_));
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['sex', 'weight']);
    is_deeply(r->rownames($x2)->values, [qw/1 2 3/]);
    is_deeply(r->colnames($x2)->values, ['sex', 'weight']);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/F M F/]);
    is_deeply($x2->getin(2)->values, [qw/5 6 7/]);
  }
  
  # get - row index and name
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(c_(2, 3), c_(1, 3));
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['sex', 'weight']);
    is_deeply(r->rownames($x2)->values, [qw/1 2/]);
    is_deeply(r->colnames($x2)->values, ['sex', 'weight']);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/M F/]);
    is_deeply($x2->getin(2)->values, [qw/6 7/]);
  }
  
  # get - row index
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get(NULL, c_(1, 3));
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['sex', 'weight']);
    is_deeply(r->rownames($x2)->values, [qw/1 2 3/]);
    is_deeply(r->colnames($x2)->values, ['sex', 'weight']);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/F M F/]);
    is_deeply($x2->getin(2)->values, [qw/5 6 7/]);
  }
  
  # get - name
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = $x1->get("weight");
    ok(r->is->data_frame($x2));
    is_deeply($x2->class->values, ['data.frame']);
    is_deeply(r->names($x2)->values, ['weight']);
  }
}

# set
{
  # set - NULL
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    $x1->at(2);
    $x1->set(NULL);
    is_deeply(r->as->character($x1->getin(1))->values, ['F', 'M', 'F']);
    is_deeply($x1->getin(2)->values, [5, 6, 7]);
    is_deeply(r->names($x1)->values, ['sex', 'weight']);
    is_deeply(r->colnames($x1)->values, ['sex', 'weight']);
  }
  
  # set - index
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    $x1->at(2)->set(c_(1, 2, 3));
    is_deeply($x1->getin('height')->values, [1, 2, 3]);
  }
}

# typeof
{
  my $x1 = data_frame(sex => c_(1, 2, 1));
  my $x2 = r->typeof($x1);
  ok(r->is->character($x2));
  is_deeply($x2->values, ['list']);
}

# subset
{
  # subset - row condition
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = r->subset($x1, $x1->getin('height') > 160);
    ok(r->is->data_frame($x2));
    is_deeply(r->names($x2)->values, ['sex', 'height', 'weight']);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/F M/]);
    is_deeply($x2->getin(2)->values, [qw/172 168/]);
    is_deeply($x2->getin(3)->values, [qw/5 6/]);
  }
  
  # subset - row condition and column names
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = r->subset($x1, $x1->getin('height') > 160, c_('sex', 'weight'));
    ok(r->is->data_frame($x2));
    is_deeply(r->names($x2)->values, ['sex', 'weight']);
    is_deeply(r->as->character($x2->getin(1))->values, [qw/F M/]);
    is_deeply($x2->getin(2)->values, [qw/5 6/]);
  }
}

# data_frame
{
  # data_frame - with I
  {
    my $sex = r->I(c_('F', 'M', 'F'));
    my $height = c_(172, 168, 155);
    
    my $x1 = data_frame(sex => $sex, height => $height);
    ok(r->is->character($x1->getin(1)));
    is_deeply($x1->getin(1)->values, ["F", "M", "F"]);
    is_deeply($x1->getin(2)->values, [172, 168, 155]);
  }
  
  # data_frame - basic
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    
    my $x1 = data_frame(sex => $sex, height => $height);
    ok(r->is->factor($x1->getin(1)));
    is_deeply($x1->getin(1)->values, [1, 2, 1]);
    is_deeply($x1->getin('sex')->values, [1, 2, 1]);
    is_deeply($x1->getin(2)->values, [172, 168, 155]);
    is_deeply($x1->getin('height')->values, [172, 168, 155]);
  }
  
  # data_frame - alias for cbind
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height);
    my $x2 = data_frame(weight => $weight);
    my $x3 = data_frame($x1, $x2);
    
    ok(r->is->data_frame($x3));
    is_deeply($x3->class->values, ['data.frame']);
    is_deeply(r->names($x3)->values, ['sex', 'height', 'weight']);
    ok(r->is->factor($x3->getin(1)));
    is_deeply(r->as->character($x3->getin(1))->values, [qw/F M F/]);
    is_deeply($x3->getin(2)->values, [172, 168, 155]);
    is_deeply($x3->getin(3)->values, [5, 6, 7]);
  }
  
  # data_frame - basic
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    
    my $x1 = data_frame(sex => $sex, height => $height);
    ok(r->is->factor($x1->getin(1)));
    is_deeply($x1->getin(1)->values, [1, 2, 1]);
    is_deeply($x1->getin('sex')->values, [1, 2, 1]);
    is_deeply($x1->getin(2)->values, [172, 168, 155]);
    is_deeply($x1->getin('height')->values, [172, 168, 155]);
  }

  # data_frame - name duplicate
  {
    my $sex = c_('a', 'b', 'c');
    my $sex1 = c_('a1', 'b1', 'c1');
    my $sex2 = c_('a2', 'b2', 'c2');
    
    my $x1 = data_frame(sex => $sex, sex => $sex1, sex => $sex2);
    is_deeply($x1->getin('sex')->values, [1, 2, 3]);
    is_deeply(r->levels($x1->getin('sex'))->values, ['a', 'b', 'c']);
    is_deeply($x1->getin('sex.1')->values, [1, 2, 3]);
    is_deeply(r->levels($x1->getin('sex.1'))->values, ['a1', 'b1', 'c1']);
    is_deeply($x1->getin('sex.2')->values, [1, 2, 3]);
    is_deeply(r->levels($x1->getin('sex.2'))->values, ['a2', 'b2', 'c2']);
  }
}

# na_omit
{
  # na_omit - minus row index
  {
    my $sex = c_(NA, 'M', 'F');
    my $height = c_(172, NA, 155);
    my $weight = c_(5, 6, 7);
    
    my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
    my $x2 = r->na_omit($x1);
    ok(r->is->data_frame($x2));
    is_deeply($x2->getin(1)->values, [qw/1/]);
    is_deeply($x2->getin(2)->values, [qw/155/]);
    is_deeply($x2->getin(3)->values, [qw/7/]);
  }
}

# head
{
  # head - default
  {
    my $v1 = c_(1, 2, 3, 4, 5, 6, 7);
    my $v2 = c_(1, 2, 3, 4, 5, 10, 11);
    
    my $x1 = data_frame(v1 => $v1, v2 => $v2);
    my $x2 = r->head($x1);
    ok(r->is->data_frame($x2));
    is_deeply($x2->getin(1)->values, [1, 2, 3, 4, 5, 6]);
    is_deeply($x2->getin(2)->values, [1, 2, 3, 4, 5, 10]);
  }
  
  # head - n
  {
    my $v1 = c_(1, 2, 3, 4);
    my $v2 = c_(1, 2, 5, 6);
    
    my $x1 = data_frame(v1 => $v1, v2 => $v2);
    my $x2 = r->head($x1, {n => 3});
    ok(r->is->data_frame($x2));
    is_deeply($x2->getin(1)->values, [1, 2, 3]);
    is_deeply($x2->getin(2)->values, [1, 2, 5]);
  }
}

# cbind
{
  my $sex = c_('F', 'M', 'F');
  my $height = c_(172, 168, 155);
  my $weight = c_(5, 6, 7);
  
  my $x1 = data_frame(sex => $sex, height => $height);
  my $x2 = data_frame(weight => $weight);
  my $x3 = r->cbind($x1, $x2);
  
  ok(r->is->data_frame($x3));
  is_deeply($x3->class->values, ['data.frame']);
  is_deeply(r->names($x3)->values, ['sex', 'height', 'weight']);
  ok(r->is->factor($x3->getin(1)));
  is_deeply(r->as->character($x3->getin(1))->values, [qw/F M F/]);
  is_deeply($x3->getin(2)->values, [172, 168, 155]);
  is_deeply($x3->getin(3)->values, [5, 6, 7]);
}

# rbind
{
  my $sex1 = c_('F', 'M');
  my $height1 = c_(172, 168);
  my $x1 = data_frame(sex => $sex1, height => $height1);

  my $sex2 = c_('M', 'F');
  my $height2 = c_(5, 6);
  my $x2 = data_frame(sex => $sex2, height => $height2);
 
  my $x3 = r->rbind($x1, $x2);
  ok(r->is->factor($x3->getin(1)));
  is_deeply(r->names($x3)->values, [qw/sex height/]);
  is_deeply(r->as->character($x3->getin(1))->values, [qw/F M M F/]);
  is_deeply($x3->getin(2)->values, [172, 168, 5, 6]);
}

# ncol
{
  my $sex = c_('F', 'M');
  my $height = c_(172, 168);
  my $weight = c_(5, 6);
  my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
  my $x2 = r->ncol($x1);
  ok($x2->values, [3]);
}

# nrow
{
  my $sex = c_('F', 'M');
  my $height = c_(172, 168);
  my $weight = c_(5, 6);
  my $x1 = data_frame(sex => $sex, height => $height, weight => $weight);
  my $x2 = r->nrow($x1);
  ok($x2->values, [2]);
}

# data_frame - to_string
{
  # data_frame - to_string
  {
    my $sex = c_('F', 'M', 'F');
    my $height = c_(172, 168, 155);
    my $x1 = data_frame(sex => $sex, height => $height);
    my $got = "$x1";
    $got =~ s/\s+/ /g;
my $expected = <<"EOS";
    sex  height
 1    F     172
 2    M     168
 3    F     155
EOS
    $expected =~ s/\s+/ /g;
    is($got, $expected);
  }
}

