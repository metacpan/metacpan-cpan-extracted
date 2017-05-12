	.file	"mux_test_4.f90"
	.section	.rodata
	.align 4
.LC0:
	.long	31
	.align 4
.LC1:
	.long	20
	.align 4
.LC2:
	.long	16
	.align 4
.LC3:
	.long	1
	.align 4
.LC4:
	.long	28
	.text
.globl MAIN__
	.type	MAIN__, @function
MAIN__:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$24, %esp
	movl	$0, 8(%esp)
	movl	$127, 4(%esp)
	movl	$70, (%esp)
	call	_gfortran_set_std
	movl	$.LC0, 16(%esp)
	movl	$.LC1, 12(%esp)
	movl	$.LC2, 8(%esp)
	movl	$.LC3, 4(%esp)
	movl	$.LC4, (%esp)
	call	someroutine_
	leave
	ret
	.size	MAIN__, .-MAIN__
	.ident	"GCC: (GNU) 4.1.2 20070925 (Red Hat 4.1.2-27)"
	.section	.note.GNU-stack,"",@progbits
