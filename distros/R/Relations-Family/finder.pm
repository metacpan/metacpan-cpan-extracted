sub create_finder {

  my $abs = shift;
  my $database = shift;

  $create = "

    DROP DATABASE IF EXISTS $database;
    CREATE DATABASE $database;
    USE $database;

    CREATE TABLE account (
       acc_id int(10) unsigned NOT NULL auto_increment,
       cust_id tinyint(3) unsigned DEFAULT '0' NOT NULL,
       balance decimal(6,2) DEFAULT '0.00' NOT NULL,
       PRIMARY KEY (acc_id),
       UNIQUE cust_id (cust_id)
    );

    INSERT INTO account (acc_id, cust_id, balance) VALUES ( '1', '1', '134.87');
    INSERT INTO account (acc_id, cust_id, balance) VALUES ( '2', '4', '54.65');
    INSERT INTO account (acc_id, cust_id, balance) VALUES ( '3', '3', '0.00');
    INSERT INTO account (acc_id, cust_id, balance) VALUES ( '4', '5', '357.72');
    INSERT INTO account (acc_id, cust_id, balance) VALUES ( '5', '2', '78.99');

    CREATE TABLE customer (
       cust_id int(10) unsigned NOT NULL auto_increment,
       cust_name varchar(32) NOT NULL,
       phone varchar(32) NOT NULL,
       PRIMARY KEY (cust_id),
       UNIQUE cust_name (cust_name)
    );

    INSERT INTO customer (cust_id, cust_name, phone) VALUES ( '1', 'Harry\\'s Garage', '555-8762');
    INSERT INTO customer (cust_id, cust_name, phone) VALUES ( '2', 'Varney Solutions', '555-8814');
    INSERT INTO customer (cust_id, cust_name, phone) VALUES ( '3', 'Simply Flowers', '555-1392');
    INSERT INTO customer (cust_id, cust_name, phone) VALUES ( '4', 'Last Night Diner', '555-0544');
    INSERT INTO customer (cust_id, cust_name, phone) VALUES ( '5', 'Teskaday Print Shop', '555-4357');

    CREATE TABLE item (
       item_id int(10) unsigned NOT NULL auto_increment,
       pur_id int(10) unsigned DEFAULT '0' NOT NULL,
       prod_id int(10) unsigned DEFAULT '0' NOT NULL,
       qty int(10) unsigned DEFAULT '0' NOT NULL,
       PRIMARY KEY (item_id),
       UNIQUE ord_id (pur_id, prod_id)
    );

    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '1', '1', '3', '2');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '2', '1', '4', '10');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '3', '1', '1', '3');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '4', '1', '2', '30');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '5', '1', '5', '14');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '6', '2', '4', '5');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '7', '2', '5', '7');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '8', '2', '2', '10');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '9', '3', '9', '1');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '10', '3', '4', '5');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '11', '3', '5', '5');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '12', '3', '2', '12');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '13', '4', '6', '1');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '14', '4', '9', '1');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '15', '4', '8', '1');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '16', '4', '7', '1');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '17', '5', '13', '24');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '18', '5', '12', '50');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '19', '5', '10', '32');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '20', '5', '11', '120');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '21', '6', '12', '12');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '22', '7', '9', '12');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '23', '8', '6', '1');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '24', '8', '9', '1');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '25', '8', '8', '1');
    INSERT INTO item (item_id, pur_id, prod_id, qty) VALUES ( '26', '8', '7', '6');

    CREATE TABLE product (
       prod_id int(10) unsigned NOT NULL auto_increment,
       prod_name varchar(16) NOT NULL,
       type_id int(10) unsigned DEFAULT '0' NOT NULL,
       PRIMARY KEY (prod_id),
       UNIQUE prod_name (prod_name)
    );

    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '1', 'Towel Dispenser', '1');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '2', 'Towels', '1');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '3', 'Soap Dispenser', '1');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '4', 'Soap', '1');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '5', 'Toilet Paper', '1');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '6', 'Answer Machine', '2');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '7', 'Phone', '2');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '8', 'Fax', '2');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '9', 'Copy Machine', '2');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '10', 'Dishes', '3');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '11', 'Silverware', '3');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '12', 'Cups', '3');
    INSERT INTO product (prod_id, prod_name, type_id) VALUES ( '13', 'Bowls', '3');

    CREATE TABLE pur_sp (
       ps_id int(10) unsigned NOT NULL auto_increment,
       pur_id int(10) unsigned DEFAULT '0' NOT NULL,
       sp_id int(10) unsigned DEFAULT '0' NOT NULL,
       PRIMARY KEY (ps_id),
       UNIQUE ord_id (pur_id, sp_id)
    );

    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '1', '1', '14');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '2', '3', '3');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '3', '4', '10');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '4', '5', '8');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '5', '5', '16');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '6', '5', '9');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '7', '6', '12');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '8', '6', '6');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '9', '6', '14');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '10', '6', '1');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '11', '7', '8');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '12', '7', '15');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '13', '7', '7');
    INSERT INTO pur_sp (ps_id, pur_id, sp_id) VALUES ( '14', '8', '4');

    CREATE TABLE purchase (
       pur_id int(10) unsigned NOT NULL auto_increment,
       cust_id int(10) unsigned DEFAULT '0' NOT NULL,
       date date DEFAULT '0000-00-00' NOT NULL,
       PRIMARY KEY (pur_id)
    );

    INSERT INTO purchase (pur_id, cust_id, date) VALUES ( '1', '1', '2000-12-07');
    INSERT INTO purchase (pur_id, cust_id, date) VALUES ( '2', '1', '2001-02-08');
    INSERT INTO purchase (pur_id, cust_id, date) VALUES ( '3', '1', '2001-04-21');
    INSERT INTO purchase (pur_id, cust_id, date) VALUES ( '4', '3', '2001-03-10');
    INSERT INTO purchase (pur_id, cust_id, date) VALUES ( '5', '4', '2000-11-03');
    INSERT INTO purchase (pur_id, cust_id, date) VALUES ( '6', '4', '2001-05-09');
    INSERT INTO purchase (pur_id, cust_id, date) VALUES ( '7', '5', '2001-04-07');
    INSERT INTO purchase (pur_id, cust_id, date) VALUES ( '8', '2', '2001-01-04');

    CREATE TABLE region (
       reg_id int(10) unsigned NOT NULL auto_increment,
       reg_name varchar(16) NOT NULL,
       PRIMARY KEY (reg_id),
       UNIQUE reg_name (reg_name)
    );

    INSERT INTO region (reg_id, reg_name) VALUES ( '1', 'North East');
    INSERT INTO region (reg_id, reg_name) VALUES ( '2', 'South East');
    INSERT INTO region (reg_id, reg_name) VALUES ( '3', 'South West');
    INSERT INTO region (reg_id, reg_name) VALUES ( '4', 'North West');

    CREATE TABLE sales_person (
       sp_id int(10) unsigned NOT NULL auto_increment,
       f_name varchar(32) NOT NULL,
       l_name varchar(32) NOT NULL,
       reg_id int(10) unsigned DEFAULT '0' NOT NULL,
       PRIMARY KEY (sp_id),
       UNIQUE f_name (f_name, l_name)
    );

    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '1', 'John', 'Lockland', '1');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '2', 'Mimi', 'Butterfield', '4');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '3', 'Sheryl', 'Saunders', '2');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '4', 'Frank', 'Macena', '1');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '5', 'Joyce', 'Parkhurst', '3');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '6', 'Dave', 'Gropenhiemer', '4');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '7', 'Hank', 'Wishings', '2');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '8', 'Fred', 'Pirozzi', '3');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '9', 'Sally', 'Rogers', '3');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '10', 'Jane', 'Wadsworth', '4');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '11', 'Ravi', 'Svenka', '1');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '12', 'Jennie', 'Dryden', '1');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '13', 'Mike', 'Nicerby', '4');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '14', 'Karen', 'Harner', '2');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '15', 'Jose', 'Salina', '3');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '16', 'Mya', 'Protaste', '2');
    INSERT INTO sales_person (sp_id, f_name, l_name, reg_id) VALUES ( '17', 'Calvin', 'Peterson', '1');

    CREATE TABLE type (
       type_id int(10) unsigned NOT NULL auto_increment,
       type_name varchar(8) NOT NULL,
       PRIMARY KEY (type_id),
       UNIQUE type_name (type_name)
    );

    INSERT INTO type (type_id, type_name) VALUES ( '1', 'Toiletry');
    INSERT INTO type (type_id, type_name) VALUES ( '2', 'Office');
    INSERT INTO type (type_id, type_name) VALUES ( '3', 'Dining')
    
  ";

  @create = split ';',$create;

  foreach $create (@create) {

    $abs->run_query($create);

  }

}

sub relate_finder {

  my $abs = shift;
  my $database = shift;

  my $fam = new Relations::Family($abs);

  $fam->add_member(-name     => 'account',
                   -label    => 'Cust. Account',
                   -database => $database,
                   -table    => 'account',
                   -id_field => 'acc_id',
                   -query    => {-select   => {'id'    => 'acc_id',
                                               'label' => "concat(cust_name,' - ',balance)"},
                                 -from     => ['account','customer'],
                                 -where    => "customer.cust_id=account.cust_id",
                                 -order_by => "cust_name"});

  $fam->add_member(-name     => 'customer',
                   -label    => 'Customer',
                   -database => $database,
                   -table    => 'customer',
                   -id_field => 'cust_id',
                   -query    => {-select   => {'id'    => 'cust_id',
                                               'label' => 'cust_name'},
                                 -from     => 'customer',
                                 -order_by => "cust_name"});

  $fam->add_member(-name     => 'item',
                   -label    => 'Purchase Item',
                   -database => $database,
                   -table    => 'item',
                   -id_field => 'item_id',
                   -query    => {-select   => {'id'    => 'item_id',
                                               'label' => "concat(
                                                            cust_name,
                                                            ' - ',
                                                            date_format(date, '%M %D, %Y'),
                                                            ' - ',
                                                            prod_name,
                                                            ' - ',
                                                            qty
                                                          )"},
                                 -from     => ['purchase',
                                               'customer',
                                               'product',
                                               'item'],
                                 -where    => ['purchase.pur_id=item.pur_id',
                                               'product.prod_id=item.prod_id',
                                               'customer.cust_id=purchase.cust_id'],
                                 -order_by => ['date desc',
                                               'cust_name',
                                               'prod_name']});

  $fam->add_member(-name     => 'product',
                   -label    => 'Product',
                   -database => $database,
                   -table    => 'product',
                   -id_field => 'prod_id',
                   -query    => {-select   => {'id'    => 'prod_id',
                                               'label' => 'prod_name'},
                                 -from     => 'product',
                                 -order_by => "prod_name"});

  $fam->add_member(-name     => 'pur_sp',
                   -label    => 'Purchase via Sales Person',
                   -database => $database,
                   -table    => 'pur_sp',
                   -id_field => 'ps_id',
                   -query    => {-select   => {'id'    => 'ps_id',
                                               'label' => "concat(
                                                            cust_name,
                                                            ' - ',
                                                            date_format(date, '%M %D, %Y'),
                                                            ' via ',
                                                            f_name,
                                                            ' ',
                                                            l_name
                                                          )"},
                                 -from     => ['pur_sp',
                                               'purchase',
                                               'customer',
                                               'sales_person'],
                                 -where    => ['purchase.pur_id=pur_sp.pur_id',
                                               'customer.cust_id=purchase.cust_id',
                                               'sales_person.sp_id=pur_sp.sp_id'],
                                 -order_by => ['date desc',
                                               'cust_name',
                                               'l_name',
                                               'f_name']});

  $fam->add_member(-name     => 'purchase',
                   -label    => 'Purchase',
                   -database => $database,
                   -table    => 'purchase',
                   -id_field => 'pur_id',
                   -query    => {-select   => {'id'    => 'pur_id',
                                               'label' => "concat(
                                                            cust_name,
                                                            ' - ',
                                                            date_format(date, '%M %D, %Y')
                                                          )"},
                                 -from     => ['purchase',
                                               'customer'],
                                 -where    => 'customer.cust_id=purchase.cust_id',
                                 -order_by => ['date desc',
                                               'cust_name']});

  $fam->add_member(-name     => 'region',
                   -label    => 'Region',
                   -database => $database,
                   -table    => 'region',
                   -id_field => 'reg_id',
                   -query    => {-select   => {'id'    => 'reg_id',
                                               'label' => 'reg_name'},
                                 -from     => 'region',
                                 -order_by => "reg_name"});

  $fam->add_member(-name     => 'sales_person',
                   -label    => 'Sales Person',
                   -database => $database,
                   -table    => 'sales_person',
                   -id_field => 'sp_id',
                   -query    => {-select   => {'id'    => 'sp_id',
                                               'label' => "concat(f_name,' ',l_name)"},
                                 -from     => 'sales_person',
                                 -order_by => ["l_name","f_name"]});

  $fam->add_member(-name     => 'type',
                   -label    => 'Type',
                   -database => $database,
                   -table    => 'type',
                   -id_field => 'type_id',
                   -query    => {-select   => {'id'    => 'type_id',
                                               'label' => 'type_name'},
                                 -from     => 'type',
                                 -order_by => "type_name"});

  $fam->add_lineage(-parent_name  => 'purchase',
                    -parent_field => 'pur_id',
                    -child_name   => 'item',
                    -child_field  => 'pur_id');

  $fam->add_lineage(-parent_name  => 'product',
                    -parent_field => 'prod_id',
                    -child_name   => 'item',
                    -child_field  => 'prod_id');

  $fam->add_lineage(-parent_name  => 'type',
                    -parent_field => 'type_id',
                    -child_name   => 'product',
                    -child_field  => 'type_id');

  $fam->add_lineage(-parent_name  => 'purchase',
                    -parent_field => 'pur_id',
                    -child_name   => 'pur_sp',
                    -child_field  => 'pur_id');

  $fam->add_lineage(-parent_name  => 'sales_person',
                    -parent_field => 'sp_id',
                    -child_name   => 'pur_sp',
                    -child_field  => 'sp_id');

  $fam->add_lineage(-parent_name  => 'customer',
                    -parent_field => 'cust_id',
                    -child_name   => 'purchase',
                    -child_field  => 'cust_id');

  $fam->add_lineage(-parent_name  => 'region',
                    -parent_field => 'reg_id',
                    -child_name   => 'sales_person',
                    -child_field  => 'reg_id');

  $fam->add_rivalry(-brother_name  => 'customer',
                    -brother_field => 'cust_id',
                    -sister_name   => 'account',
                    -sister_field  => 'cust_id');

  $fam->add_value(-name         => 'Cust. Account',
                  -sql          => "concat(cust_name,' - ',balance)",
                  -member_names => 'customer,account');

  $fam->add_value(-name         => 'Paid',
                  -sql          => "if(balance > 0,'NO','YES')",
                  -member_names => 'account');

  $fam->add_value(-name         => 'Customer',
                  -sql          => 'cust_name',
                  -member_names => 'customer');

  $fam->add_value(-name         => 'Purchase Item',
                  -sql          => "concat(
                                    cust_name,
                                    ' - ',
                                    date_format(date, '%M %D, %Y'),
                                    ' - ',
                                    prod_name,
                                    ' - ',
                                    qty
                                   )",
                  -member_names => 'purchase,customer,product,item');

  $fam->add_value(-name         => 'Product',
                  -sql          => 'prod_name',
                  -member_names => 'product');

  $fam->add_value(-name         => 'Purchase',
                  -sql          => "concat(
                                      cust_name,
                                      ' - ',
                                      date_format(date, '%M %D, %Y')
                                    )",
                  -member_names => 'purchase,customer');

  $fam->add_value(-name         => 'Purchase via Sales Person',
                  -sql          => "concat(
                                    cust_name,
                                    ' - ',
                                    date_format(date, '%M %D, %Y'),
                                    ' via ',
                                    f_name,
                                    ' ',
                                    l_name
                                  )",
                  -member_names => ['pur_sp',
                                    'purchase',
                                    'customer',
                                    'sales_person']);

  $fam->add_value(-name         => 'Region',
                  -sql          => 'reg_name',
                  -member_names => 'region');

  $fam->add_value(-name         => 'Sales Person',
                  -sql          => "concat(f_name,' ',l_name)",
                  -member_names => 'sales_person');

  $fam->add_value(-name         => 'Type',
                  -sql          => 'type_name',
                  -member_names => 'type');

  $fam->add_value(-name  => 'Sold',
                  -sql   => 'sum(item.qty)',
                  -member_names => 'item');

  return $fam;

}

1;