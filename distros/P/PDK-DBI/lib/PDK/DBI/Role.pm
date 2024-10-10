package PDK::DBI::Role;

use v5.30;
use Moose::Role;
use Carp qw(croak);
use namespace::autoclean;

has dsn => (is => 'ro', isa => 'Str', required => 1,);

has user => (is => 'ro', isa => 'Str', required => 1,);

has password => (is => 'ro', isa => 'Str', required => 1,);

has dbi => (is => 'ro', lazy => 1, builder => '_buildDbi',);

requires qw(clone batchExecute);


sub getAttrMembers {
  my ($self, $attrTypes, $dataObj) = @_;
  my $attrMembers = {};
  my ($min, $max) = (0, 0);

  for my $attr (keys %$attrTypes) {
    my $attrType = $attrTypes->{$attr};
    $attrMembers->{$attr} = do {
      if    ($attrType eq '@')  { $dataObj->$attr }
      elsif ($attrType eq '%k') { [keys %{$dataObj->$attr}] }
      elsif ($attrType eq '%v') { [values %{$dataObj->$attr}] }
      else                      { croak "未知的属性类型: $attrType" }
    };

    my $length = @{$attrMembers->{$attr}};
    $max = $length if $length > $max;
    $min = $length if $length < $min || $min == 0;
  }

  return wantarray ? ($attrMembers, $max, $min) : $attrMembers;
}

sub parseColumnMap {
  my ($self, $columnMap) = @_;
  croak "错误: columnMap 参数不是一个数组的引用" if ref($columnMap) ne 'ARRAY';

  my ($attrWhichIsSingle, $attrWhichContainList, $attrTypes) = ({}, {}, {});

  for my $columnInfo (@$columnMap) {
    if ($columnInfo =~ /^\s*(?<column>\w+)\s*(?:=>\s*(?<attr>\w+))?\s*(?:\|\s*(?<attrType>[@%k%v]))?\s*$/) {
      my ($column, $attr, $attrType) = @+{qw(column attr attrType)};
      $attr //= $column;

      if (defined $attrType) {
        $attrWhichContainList->{$column} = $attr;
        $attrTypes->{$attr}              = $attrType;
      }
      else {
        $attrWhichIsSingle->{$column} = $attr;
      }
    }
    else {
      croak "错误: columnMap 中的元素 $columnInfo 格式不符合要求";
    }
  }

  return ($attrWhichIsSingle, $attrWhichContainList, $attrTypes);
}

sub batchInsert {
  my ($self, $columnMap, $tableName, $dataObjs) = @_;

  return unless defined $dataObjs;
  croak "错误: dataObjs 参数不是一个 hash 的引用也不是一个数组的引用" if ref($dataObjs) !~ /^(?:HASH|ARRAY)$/;

  my ($attrWhichIsSingle, $attrWhichContainList, $attrTypes) = $self->parseColumnMap($columnMap);

  my @columns      = (keys %$attrWhichIsSingle, keys %$attrWhichContainList);
  my $placeholders = join ',', ('?') x @columns;
  my $sqlString    = "INSERT INTO $tableName (" . join(',', @columns) . ") VALUES ($placeholders)";

  my @params;
  for my $dataObj (values %$dataObjs) {
    my @baseParam = map { $dataObj->$_ } values %$attrWhichIsSingle;

    if (not %$attrTypes) {
      push @params, \@baseParam;
    }
    else {
      my ($attrMembers, $maxAttrMemberNums) = $self->getAttrMembers($attrTypes, $dataObj);
      for my $i (0 .. $maxAttrMemberNums - 1) {
        my @param = (@baseParam, map { $attrMembers->{$attrWhichContainList->{$_}}[$i] } keys %$attrWhichContainList);
        push @params, \@param;
      }
    }
  }

  $self->batchExecute(\@params, $sqlString);
}

1;
