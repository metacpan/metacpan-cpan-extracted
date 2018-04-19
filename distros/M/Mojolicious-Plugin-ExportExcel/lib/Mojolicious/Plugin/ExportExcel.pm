package Mojolicious::Plugin::ExportExcel;

use Mojo::Base 'Mojolicious::Plugin';
use Spreadsheet::WriteExcel;
use Clone qw/clone/;
use Mojo::JSON qw/to_json/;

sub export_excel_renderer{
  my ($r, $c, $output, $options) = @_;
  
  # 不需要编码
  delete $options->{encoding};
  
  # 设置渲染格式
  $options->{format} = 'xls';
  
  if($c->stash->{excel} && !(ref $c->stash->{excel})){
    ${$output} = $c->stash->{excel};
    return 1;
  }
  
  my $excel = $c->stash->{excel};
  unless(ref $excel eq "HASH"){
    $c->reply->exception("the param [excel] require hashref or string");
    return undef;
  }
  
  ## $settings 是 excel 表的配置信息
  my $settings = $excel->{settings} || {};
  
  ## $settings 是 excel 表的数据信息
  my $data = $excel->{data};
  
  ## $settings 是 excel 表的渲染规则
  my $option = $excel->{option};
  
  ## 数据不满足要求 则不渲染
  unless(ref $settings eq "HASH" && ref $data eq "ARRAY" && ref $option eq "ARRAY"){
    $c->reply->exception("the param is invalid: settings require HASH; data require ARRAY; option require ARRAY");
    return undef;
  }
  
  
  ## 创建内存文件
  open my $excel_file, '>', \my $excel_content;
  ## 创建 excel 对象
  my $excel_obj = Spreadsheet::WriteExcel->new($excel_file);
  ## 在 excel 中创建一个电子表 sheet
  my $ss = $excel_obj->add_worksheet($settings->{sheet_name});
  
  
  ##----------------------共用的格式写在下面--------------------------
  ## 表头的样式
  my $header_format = delete $settings->{header_format} || {bold => 1};
  
  ## 表头高度
  my $header_height = delete $settings->{header_height} || 20;
  
  ## 数据行的样式
  my $data_format = delete $settings->{data_format} || {};
  
  ## 样式缓存，一个表中能添加的样式是有限的，多了后面的就不起效果了
  my $df_cache = {};
  
  ## 数据行高度
  my $data_height = delete $settings->{data_height} || 20;
  
  ## 条件样式
  my $condition_format = delete $settings->{condition_format} || {};
  
  ##----------------------共用的格式写在上面--------------------------
  
  
  
  ## 开始渲染
  my $heading = [];
  
  ## 计算表头
  my $col = 0;
  foreach my $o(@{$option}){
    if($o->{header}){
      push(@{$heading}, $o->{header});
    }else{
      push(@{$heading}, $o->{key});
    }
    $ss->set_column($col, $col, $o->{width}) if($o->{width});
    $col++;
  }
  my $row = 0;
  $ss->set_row($row, $header_height);
  $ss->write_row($row, 0, $heading, $excel_obj->add_format(%{$header_format}));
  $row++;
  
  ## 对数据依照渲染规则进行渲染
  foreach my $srd (@{$data}){
    $col = 0;
    
    ## 计算得到当前行的格式
    my $rf = clone($data_format);
    if($condition_format->{row} && @{$condition_format->{row}}){
      foreach(@{$condition_format->{row}}){
        if($_->{condition}->($srd->{$_->{key}})){
          $rf = {%{$rf}, $_->{format} ? %{$_->{format}} : ()};
        }
      }
    }
    
    $ss->set_row($row, $data_height);
    
    foreach my $o(@{$option}){
      my $d = $srd->{$o->{key}};
      
      ## 单元格样式
      my $cf = {%{$rf}, $o->{format} ? %{$o->{format}} : ()};
      
      if($condition_format->{cell} && $condition_format->{cell}->{$o->{key}}){
        if($condition_format->{cell}->{$o->{key}}->{condition}->($d)){
          my $tf = $condition_format->{cell}->{$o->{key}}->{format};
          $cf = {%{$cf}, $tf ? %{$tf} : ()};
        }
      }
      
      if($o->{map}){
        $d = $o->{map}->{$d} || $o->{map}->{default};
      }elsif($o->{action}){
        $d = $o->{action}->($d, $srd);
      }
      
      my $df;
      my $cf_json = to_json($cf);
      if($df_cache->{$cf_json}){
        $df = $df_cache->{$cf_json};
      }else{
        $df_cache->{$cf_json} = $df = $excel_obj->add_format(%{$cf});
      }
      if($o->{type} eq "number"){
        $ss->write_number($row, $col, $d, $df);
      }elsif($o->{type} eq "string"){
        $ss->write_string($row, $col, $d, $df);
      }elsif($o->{type} eq "url"){
        $ss->write_url($row, $col, $d, $df);
      }else{
        $ss->write($row, $col, $d, $df);
      }
      $col++;
    }
    $row++;
  }
  
  $excel_obj->close;
  
  ## 设置输出
  ${$output} = $excel_content;
  
  return 1;
}

sub register{
  my ($self, $app) = @_;
  
  $app->types->type(xls => 'application/vnd.ms-excel');
  $app->renderer->add_handler(xls => \&export_excel_renderer);
  $app->helper(
    render_excel => sub{
      shift->render(handler => 'xls', @_);
    }
  );
}

=head1 NAME

Mojolicious::Plugin::ExportExcel - The great new Mojolicious::Plugin::ExportExcel!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.1.1';


=head1 SYNOPSIS


    # Mojolicious
    $self->plugin('ExportExcel');
 
    # Mojolicious::Lite
    plugin 'ExportExcel';


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

Mojolicious::Plugin::ExportExcel 覆盖了Mojolicious::Plugin中的register方法。

=head2 register

向Mojolicious的renderer中添加了一个handler：xls，用于渲染Excel文件。
向Mojolicious中添加一个helper:render_excel，用于渲染Excel文件。



=head2 export_excel_renderer

执行xls handler时的渲染方法。



=head1 PARAMETER


=head2 option

    my $option = [
      {
        key    => "recharge_status", ## 从 data的当前hash中取哪个键的值放入对应单元格
        header => "状态",            ## 对应列的表头
        map    => {                  ## 需要对用key从data取出的当前值做映射转换的规则
          0 => "待支付",
          2 => "待付款",
          3 => "完成",
          4 => "取消"
        },
        action=>sub{                   ## action 与 map 只有一个工作，且map优先级高
          ## 接收两个参数，
          ## 第一个为 当前单元格的值
          ## 第二个为 当前行的hash对象
          ## 返回的值会被作为当前单元格的最值写入excel表中
          ## 其实功能与 map 类似
        }
        type=>"string",             ## 数据类型，string,number,url
        format=>{},                  ## 对应列的样式
      },
      ……
    ];
  

=head2 settings

一个存储了excel表格配置信息的 hashref。

    my $settings=>{
        sheet_name    => "", ## 表格名称 默认为空
        header_format => {}, ## 表头格式 默认为加粗
        data_format   => {}, ## 数据格式 默认为无格式
        header_height => {}, ## 表头高度 默认为20
        data_height   => {}, ## 数据高度 默认为20
        condition_format=>{  ## 根据条件设置样式
            row=>[           ## 根据条件设置一行的格式
                {
                    key=>"", ## 要判断的数据行
                    condition=>sub{}, ## 判断条件
                    format=>{} ## 满足条件时的样式
                },
                ……
            ],
            cell=>{          ## 根据条件设置一个单元格的样式
                key=>{       ## key 要判断数据的键名
                    condition=>sub{}, ## 判断条件
                    format=>{} ## 满足条件时的样式
                },
                ……
            }
        },
        ‘A:A'=>100            ## 对应列的宽度
            
    }


=head2 data

一个hashref 的 arrayref ，其中存储的是要渲染成excel表格的数据。


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::ExportExcel

=cut

1; # End of Mojolicious::Plugin::ExportExcel
