package Net::MachineLearning::Sample;

use 5.006;
use strict;
use warnings;
use utf8;
use JSON;
use GD;

=encoding utf8

=head1 NAME

Net::MachineLearning::Sample - how machine learning works by demo

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

该模块是一个非常粗浅的案例，仅仅展示机器学习如何运作。

在库文件的同一目录，有0-9共10张数字图片，每张都是10x10像素的灰度PNG格式。

模块每次随机读取一个图片，将每个像素的值进行变换后，与到目标数字相似的10项权重分别相乘。

最后将每一项相乘的结果加权汇总，得到图片与目标数字的相似概率，数字越大相似度越高。

权重参数是一个JSON文件，位于库文件同一目录下的weights.json，通过get_weights.pl这个脚本产生。

正常来说，权重参数是通过大量的带标注图片，训练出来的，而不是手工调参的结果。

运行方法：

1. 首先通过cpanm安装该模块：

    $ sudo cpanm Net::MachineLearning::Sample

2. 然后通过命令行运行即可：

    $ perl -MNet::MachineLearning::Sample -e 'Net::MachineLearning::Sample->new->run'
	input numeric image: 8
	my best guess: 8

3. 或者在perl程序里调用：

    use Net::MachineLearning::Sample;
    my $ml = Net::MachineLearning::Sample->new;
    $ml->run;

=head1 SUBROUTINES/METHODS

=head2 new

new the object.

=cut

sub new {
    my $class = shift;
    bless {},$class;
}

=head2 run

run the model.

=cut

sub run {

    my $module_dir = $INC{'Net/MachineLearning/Sample.pm'};
    $module_dir =~ s/Sample\.pm$//;

    my $ix = int rand(10);
    my %scores;

    open my $fd,"$module_dir/weights.json" or die $!;
    my $json = <$fd>;
    close $fd;

    my $wht = from_json($json);

    my $myImage = newFromPng GD::Image("$module_dir/gray-$ix.png",0);
    my $pointer = 0;

    for my $column (0..9) {
        for my $row (0..9) {
            my $index = $myImage->getPixel($row,$column);

            for my $num (0..9) {
                my $weight = $wht->{$num}->[$pointer];
                $scores{$num}  += $weight * (255 - $index);
            }

            $pointer ++;
        }
    }

	my $bestValue;

	for (sort {$scores{$b} <=> $scores{$a} } keys %scores) {
		$bestValue = $_;
		last;
	}

    print "input numeric image: $ix\n";
	print "my best guess: $bestValue\n";
}


=head1 AUTHOR

Ken Peng, C<< <yhpeng at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-machinelearning-sample at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-MachineLearning-Sample>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::MachineLearning::Sample


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-MachineLearning-Sample>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-MachineLearning-Sample>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-MachineLearning-Sample>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-MachineLearning-Sample/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ken Peng.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Net::MachineLearning::Sample
