jQuery(window).load(function(){
  setTimeout(function(){ 
    jQuery('#delayed_ticket_history .titlebox-title .right').append('— <a href="javascript:void(0)" class="toggle-others">Kimenő levelek mutatása</a>')
    jQuery('#delayed_ticket_history .titlebox-title .right').append('<a href="javascript:void(0)" class="toggle-others hidden">Kimenő levelek elrejtése</a>')
    jQuery('.transaction.Ticket-transaction.other').addClass('hidden');
    jQuery(document).on('click','.toggle-others',function(){ jQuery('.transaction.Ticket-transaction.other, .toggle-others').toggleClass('hidden'); });
  }, 1000);
})


