CREATE TABLE spopstest (
  int_field         int not null,
  varchar_field     varchar(10) null,
  char_field        char(10) null,
  datetime_field    datetime null,
  text_field        text null,
  numeric_field     numeric(10,2) null,
  float_field       float null,
  ts_field          timestamp null,
  primary key ( int_field )
)