	.file	"means-3.f90"
	.section	.rodata
.LC0:
	.string	"means-3.f90"
.LC1:
	.ascii	"Class "
.LC2:
	.ascii	" has "
.LC3:
	.ascii	" students"
.LC6:
	.ascii	"----------------------"
.LC7:
	.ascii	"Class Average: "
.LC8:
	.ascii	"Grant Average: "
	.align 4
.LC5:
	.long	1077936128
	.text
.globl MAIN__
	.type	MAIN__, @function
MAIN__:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$344, %esp
	movl	$0, 8(%esp)
	movl	$127, 4(%esp)
	movl	$70, (%esp)
	call	_gfortran_set_std
	movl	$.LC0, -312(%ebp)
	movl	$21, -308(%ebp)
	movl	$5, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_read
	movl	$4, 8(%esp)
	leal	-32(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_integer
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_read_done
	movl	-32(%ebp), %eax
	movl	%eax, -328(%ebp)
	movl	$1, -4(%ebp)
	movl	-4(%ebp), %eax
	cmpl	-328(%ebp), %eax
	jg	.L8
.L3:
	movl	$.LC0, -312(%ebp)
	movl	$23, -308(%ebp)
	movl	$5, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_read
	movl	$4, 8(%esp)
	leal	-28(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_integer
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_read_done
	movl	$.LC0, -312(%ebp)
	movl	$24, -308(%ebp)
	movl	$6, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write_done
	movl	$.LC0, -312(%ebp)
	movl	$25, -308(%ebp)
	movl	$6, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write
	movl	$6, 8(%esp)
	movl	$.LC1, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_character
	movl	$4, 8(%esp)
	leal	-4(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_integer
	movl	$5, 8(%esp)
	movl	$.LC2, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_character
	movl	$4, 8(%esp)
	leal	-28(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_integer
	movl	$9, 8(%esp)
	movl	$.LC3, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_character
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write_done
	movl	$.LC0, -312(%ebp)
	movl	$26, -308(%ebp)
	movl	$6, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write_done
	movl	$0x00000000, %eax
	movl	%eax, -16(%ebp)
	movl	$0x00000000, %eax
	movl	%eax, -8(%ebp)
	movl	$0x00000000, %eax
	movl	%eax, -20(%ebp)
	movl	-28(%ebp), %eax
	movl	%eax, -324(%ebp)
	movl	$1, -44(%ebp)
	movl	-44(%ebp), %eax
	cmpl	-324(%ebp), %eax
	jg	.L4
.L5:
	movl	$.LC0, -312(%ebp)
	movl	$31, -308(%ebp)
	movl	$5, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_read
	movl	$4, 8(%esp)
	leal	-40(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	movl	$4, 8(%esp)
	leal	-36(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	movl	$4, 8(%esp)
	leal	-48(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_read_done
	flds	-16(%ebp)
	flds	-40(%ebp)
	faddp	%st, %st(1)
	fstps	-16(%ebp)
	flds	-8(%ebp)
	flds	-36(%ebp)
	faddp	%st, %st(1)
	fstps	-8(%ebp)
	flds	-20(%ebp)
	flds	-48(%ebp)
	faddp	%st, %st(1)
	fstps	-20(%ebp)
	flds	-40(%ebp)
	flds	-36(%ebp)
	faddp	%st, %st(1)
	flds	-48(%ebp)
	faddp	%st, %st(1)
	flds	.LC5
	fdivrp	%st, %st(1)
	fstps	-12(%ebp)
	movl	$.LC0, -312(%ebp)
	movl	$36, -308(%ebp)
	movl	$6, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write
	movl	$4, 8(%esp)
	leal	-44(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_integer
	movl	$4, 8(%esp)
	leal	-40(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	movl	$4, 8(%esp)
	leal	-36(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	movl	$4, 8(%esp)
	leal	-48(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	movl	$4, 8(%esp)
	leal	-12(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write_done
	movl	-44(%ebp), %eax
	cmpl	-324(%ebp), %eax
	sete	%al
	movzbl	%al, %edx
	movl	-44(%ebp), %eax
	addl	$1, %eax
	movl	%eax, -44(%ebp)
	testl	%edx, %edx
	jne	.L4
	jmp	.L5
.L4:
	movl	$.LC0, -312(%ebp)
	movl	$38, -308(%ebp)
	movl	$6, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write
	movl	$22, 8(%esp)
	movl	$.LC6, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_character
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write_done
	flds	-16(%ebp)
	movl	-28(%ebp), %eax
	pushl	%eax
	fildl	(%esp)
	leal	4(%esp), %esp
	fdivrp	%st, %st(1)
	fstps	-16(%ebp)
	flds	-8(%ebp)
	movl	-28(%ebp), %eax
	pushl	%eax
	fildl	(%esp)
	leal	4(%esp), %esp
	fdivrp	%st, %st(1)
	fstps	-8(%ebp)
	flds	-20(%ebp)
	movl	-28(%ebp), %eax
	pushl	%eax
	fildl	(%esp)
	leal	4(%esp), %esp
	fdivrp	%st, %st(1)
	fstps	-20(%ebp)
	flds	-16(%ebp)
	flds	-8(%ebp)
	faddp	%st, %st(1)
	flds	-20(%ebp)
	faddp	%st, %st(1)
	flds	.LC5
	fdivrp	%st, %st(1)
	fstps	-24(%ebp)
	movl	$.LC0, -312(%ebp)
	movl	$43, -308(%ebp)
	movl	$6, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write
	movl	$15, 8(%esp)
	movl	$.LC7, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_character
	movl	$4, 8(%esp)
	leal	-16(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	movl	$4, 8(%esp)
	leal	-8(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	movl	$4, 8(%esp)
	leal	-20(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write_done
	movl	$.LC0, -312(%ebp)
	movl	$44, -308(%ebp)
	movl	$6, -316(%ebp)
	movl	$128, -320(%ebp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write
	movl	$15, 8(%esp)
	movl	$.LC8, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_character
	movl	$4, 8(%esp)
	leal	-24(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_transfer_real
	leal	-320(%ebp), %eax
	movl	%eax, (%esp)
	call	_gfortran_st_write_done
	movl	-4(%ebp), %eax
	cmpl	-328(%ebp), %eax
	sete	%al
	movzbl	%al, %edx
	movl	-4(%ebp), %eax
	addl	$1, %eax
	movl	%eax, -4(%ebp)
	testl	%edx, %edx
	jne	.L8
	jmp	.L3
.L8:
	leave
	ret
	.size	MAIN__, .-MAIN__
	.ident	"GCC: (GNU) 4.1.2 20070925 (Red Hat 4.1.2-27)"
	.section	.note.GNU-stack,"",@progbits
