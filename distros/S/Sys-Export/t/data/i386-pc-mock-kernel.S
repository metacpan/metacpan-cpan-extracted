# This displays the value of DX passed by the boot loader and then
# renders a rotating spinner and does nothing else.
# It's used as a way to see if the MBR loaded and transferred control to the partition.

.equ GRUB_BOOT_MACHINE_KERNEL_ADDR, 0x8000
.equ BOOT_STACK_OFS, 0x6000

# Frame pointer offsets for local variables
.equ SPINNER_IDX, 0
.equ DIGIT_BUF, 2

   .section .boot, "ax"
   .code16
   .globl _start

_start = 0x8000
   cli
   /* Set up segments and stack */
   movw $BOOT_STACK_OFS, %sp   # Stack downward from BOOT_STACK_OFS
   movw %sp, %bp               # Local vars upward from BOOT_STACK_OFS
   sti
   pushw %dx

   movw $msg_Mock_Kernel, %si
   call print

   movw $msg_DX_eq, %si
   call print
   xorl %eax, %eax
   popw %ax
   call print_eax
   movw $msg_CRLF, %si
   call print

spinner:
   movw SPINNER_IDX(%bp), %bx
   incw %bx
   andw $3, %bx
   movw %bx, SPINNER_IDX(%bp)
   movb msg_SpinChars(%bx), %al
   movw $(msg_SpinChars + 4), %si
   movb %al, (%si)
   call print
   jmp spinner

# Print null-terminated string
# Input: %si = string pointer
print:
print_next_ch:
   lodsb
   testb	%al, %al
   jz	print_done
   movw	$0x0001, %bx
   movb	$0xe, %ah
   int	$0x10
   jmp	print_next_ch
print_done:
   ret

# Print each digit of EAX in decimal.
print_eax:
   lea    (DIGIT_BUF + 11)(%bp), %si  # si points to end of DIGIT_BUF[10 digits + NUL]
   movb   $0, (%si)          # store NUL terminator
   movl   $10, %ebx
print_eax_next_digit:
   xorl   %edx, %edx
   divl   %ebx               # divide EAX by 10; quotient in EAX, remainder in EDX
   addb   $'0', %dl          # convert remainder to ASCII
   decw   %si
   movb   %dl, (%si)
   testl  %eax, %eax
   jnz    print_eax_next_digit
   jmp    print              # print null-terminated string in si

# Error handler - print '<!>' and halt
error:
   movw   $msg_ERR, %si
   call   print
   int    $0x18 # BIOS boot failure
halt:
   jmp    halt

# Data section
msg_Mock_Kernel:
   .ascii "Mock Kernel"
msg_CRLF:
   .asciz "\r\n"
msg_DX_eq:
   .asciz "DX = "
msg_SpinChars:
   .asciz "\\|/- \r"
msg_ERR:
   .asciz "ERROR"
