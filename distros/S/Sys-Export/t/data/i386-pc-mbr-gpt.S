# This MBR boot loader is a replacement for GRUB stage 1 and stage 1.5.
# This loader assumes a BIOS capable of loading blocks by LBA, and a GPT partition label.
# It reads the GPT partition label looking for the partition with GRUB's boot loader type,
# then loads that entire partition (up to 512K) as stage 2 and executes it.
# This supports reading the partition from a 64-bit LBA, and provides some
# status feedback as it loads.

.equ GRUB_BOOT_MACHINE_KERNEL_ADDR, 0x8000
.equ LBA_LOAD_TO_SEG, 0x800  # chosen to be the same as GRUB_BOOT_MACHINE_KERNEL_ADDR
.equ BOOT_STACK_OFS, 0x6000

# Frame pointer offsets for local variables
.equ BOOT_DRIVE, 0          # initial value of DX
.equ KERNEL_SEC_COUNT, 2    # Count of sectors to load for kernel (16-bit)
.equ GPT_ENT_SIZE, 4        # Size (bytes) of one GPT partition entry
.equ GPT_ENT_TOTAL, 8       # Count of GPT partition entries
.equ INT13_DAP, 12          # Buffer holding Disk Address Packet for INT13 LBA disk read
.equ INT13_DAP_SIZE, 12     # dap.size, constant 0x0010
.equ INT13_DAP_COUNT, 14    # dap.count, number of sectors to read
.equ INT13_DAP_BUF_OFS, 16  # dap.buf_ofs
.equ INT13_DAP_BUF_SEG, 18  # dap.buf_seg
.equ INT13_DAP_LBA_LOW, 20  # dap.lba_low
.equ INT13_DAP_LBA_HIGH, 24 # dap.lba_high
.equ DIGIT_BUF, 28          # Buffer for int-to-string conversion
.equ INT13_DAP_FROM_DS, BOOT_STACK_OFS+INT13_DAP # DAP as seen from data segment pointer

   .section .boot, "ax"
   .code16
   .globl _start

_start = 0x7C00
   cli
   # Normalize CS:IP to 0000:7c00
   ljmp    $0, $start

start:
   # Set up segments and stack
   xorw %ax, %ax
   movw %ax, %ds
   movw %ax, %ss
   movw $LBA_LOAD_TO_SEG, %ax
   movw %ax, %es               # es will point to the data we load with IN13h AH=42h
   movw $BOOT_STACK_OFS, %sp   # Stack downward from BOOT_STACK_OFS
   movw %sp, %bp               # Local vars upward from BOOT_STACK_OFS
   sti

   # Save boot drive
   movw	%dx, BOOT_DRIVE(%bp)

   # Print "MBR " to show we started
   movw	$msg_MBR, %si
   call	print

   # Read GPT header (LBA 1)
   xorl %eax, %eax
   movl %eax, INT13_DAP_LBA_HIGH(%bp)
   incl %eax           # LBA 1
   movl %eax, INT13_DAP_LBA_LOW(%bp)
   movw %ax, %cx       # 1 sector
   movw $msg_GPT, %si  # success message
   call read_disk

   # Sanity check, must start with "EFI "
   cmpl $0x20494645, %es:0
   jne error
   
   # Calculate sectors needed for partition entries
   movl %es:0x50, %eax  # number of entries
   movl %es:0x54, %ecx  # size of entry
   # sanity check, normally 128 but at most needs to fit in 16 bit
#   cmpl $0x8000, %ecx
#   ja error
   movl %ecx, %ebx
   shrl $15, %ebx
   jnz error
   movl %ecx, GPT_ENT_SIZE(%bp)  # save entry size
   mull %ecx                     # total bytes needed
   movl %eax, GPT_ENT_TOTAL(%bp) # save total bytes
   addl $511, %eax               # round up
   shrl $9, %eax                 # divide by 512

   # Read partition entries
   movw %ax, %cx                 # sector count
   movl %es:0x48, %eax
   movl %eax, INT13_DAP_LBA_LOW(%bp)  # LBA-low from GPT header
   movl %es:0x4C, %eax
   movl %eax, INT13_DAP_LBA_HIGH(%bp) # LBA-high from GPT header
   movw $msg_ENT, %si            # success message
   call read_disk

   # Search for Type-GUID "Hah!IdontNeedEFI" in partition entries
   # %ebx increments by GPT_ENT_SIZE until it reaches GPT_ENT_TOTAL
   # GPT_ENT_SIZE is assumed to be 64K or less (4x the size of a normal GPT array)
   # and if it is larger it will re-scan earlier partitions to no effect and fail.
   xorl %ebx, %ebx
search_loop:
   cmpl	GPT_ENT_TOTAL(%bp), %ebx
   jae	error

   # Compare 16-byte GUID
   movw	%bx,   %di
   movw	$guid, %si
   movw	$16,   %cx
   repe cmpsb
   je	found_partition

   # Next entry (entry size from frame)
   addl GPT_ENT_SIZE(%bp), %ebx
   jmp  search_loop

found_partition:
   pushw %bx
   # Print decimal number of partition entry
   movl  %ebx, %eax
   cdq   # zero %edx
   divl  GPT_ENT_SIZE(%bp)
   call  print_eax

   movw  $msg_FROM, %si
   call  print

   # Get first LBA (offset 32) and last LBA (offset 40)
   popw %bx
   movl %es:36(%bx), %eax   # first LBA-high
   movl %eax, INT13_DAP_LBA_HIGH(%bp)
   movl %es:32(%bx), %eax   # first LBA-low
   movl %eax, INT13_DAP_LBA_LOW(%bp)
   movl	%es:40(%bx), %ecx   # last LBA-low

   # Calculate sector count = last - first + 1
   # 64 bit subtraction would be awkward, and certainly safe to assume that
   # size of GRUB partition is less than 2TB.  We clamp it anyway.
   subl	%eax, %ecx
   incl	%ecx

   # Limit to 1024 sectors (512KB) - check if >= 1024
   movl	%ecx, %edx
   shrl	$10, %edx
   jz	load_partition
   movw	$1024, %cx
load_partition:
   pushw %cx

   # Print "SECTOR +COUNT" in decimal
   call  print_eax

   movw  $msg_plus, %si
   call  print

   xorl  %eax, %eax
   popw %ax
   pushw %ax
   call  print_eax

   # Load partition to memory
   popw  %cx
   movw  $msg_LOADED, %si
   call  read_disk

boot_stage2:
   # Jump to stage 2 with boot drive in DX
   movw  BOOT_DRIVE(%bp), %dx
   ljmp  $0, $GRUB_BOOT_MACHINE_KERNEL_ADDR

# Read disk using INT 13h AH=42h (LBA) and store at LBA_LOAD_TO_SEG:0
# Input:  Address to load: INT13_DAP_LBA_LOW(%bp), INT13_DAP_LBA_HIGH(%bp)
#         %cx = nonzero total sector count (16-bit)
#         %si = address of message to display on success
# Handles reading 32K at a time to avoid spanning 64K segments of real address space.
#
read_disk:
   pushw %si
   # Initialize constant fields of DAP struct
   movw $16,  INT13_DAP_SIZE(%bp)      # always 0x0010
   movw $64,  INT13_DAP_COUNT(%bp)     # always (32K/512=64) until final loop iteration
   movw $0,   INT13_DAP_BUF_OFS(%bp)   # always 0x0000
   movw %es,  INT13_DAP_BUF_SEG(%bp)   # starts at LBA_LOAD_TO_SEG and iterates by (32K/16)
read_loop:
   # Determine chunk size (max 32K = 64 sectors)
   cmpw  $64, %cx   # default is moving 64 sectors; is cx less than that?
   jae   chunk_ok   # if cx >= 64, use 64
   movw  %cx, INT13_DAP_COUNT(%bp)  # cx < 64, final loop iteration
chunk_ok:
   pushw %cx
   # Perform read
   movw $INT13_DAP_FROM_DS, %si
   movw BOOT_DRIVE(%bp), %dx
   movb	$0x42, %ah
   int	$0x13
   jc	error
   popw	%cx
   subw $64, %cx  # update remaining count
   jle  read_done

   # LBA += 64  (32K)
   addl	$64, INT13_DAP_LBA_LOW(%bp)
   adcl $0, INT13_DAP_LBA_HIGH(%bp)
   # Destination segment += 2048 (32K)
   addw $2048, INT13_DAP_BUF_SEG(%bp)
   jmp	read_loop
read_done:
   popw %si
   # fall into print routine to print success message

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
msg_MBR:
   .asciz "MBR->"
msg_GPT:
   .asciz "GPT->"
msg_ENT:
   .asciz "["
msg_FROM:
   .asciz "]: "
msg_plus:
   .asciz " +"
msg_LOADED:
   .asciz " LOADED\r\n"
msg_ERR:
   .asciz "!\r\n"

# GRUB BIOS boot partition GUID: "Hah!IdontNeedEFI"
guid:
   .byte 0x48, 0x61, 0x68, 0x21 # "Hah!"
   .byte 0x49, 0x64, 0x6F, 0x6E # "Idon"
   .byte 0x74, 0x4E, 0x65, 0x65 # "tNee"
   .byte 0x64, 0x45, 0x46, 0x49 # "dEFI"

# Pad to 440 bytes, then add disk signature area
   . = 0x1b8
disk_signature:
   .long 0
   .word 0

# Partition table (filled by partitioning tools)
   . = 0x1be
partition_table:
   .fill 64, 1, 0

# Boot signature
   .word 0xaa55
