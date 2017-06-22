
function promptSubComment(post_url,parent_id) {
  
  var html = [
    '<h3>Reply to comment:</h3>',
    '<form action="',post_url,'" method="post">',
      '<input name="parent_id" type="hidden" value="',parent_id,'" />',
      '<textarea name="body" style="width:100%;height: 150px;"></textarea>',
      '<button class="btn btn-primary" type="submit">Comment</button>',
    '</form>'
  ].join('');

  
  var modal = picoModal({
      content: html,
      overlayClose: false,
      closeHtml: "<span>Cancel</span>",
      closeStyles: {
          position: "absolute", bottom: "15px", right: "10px",
          background: "#eee", padding: "5px 10px", cursor: "pointer",
          borderRadius: "5px", border: "1px solid #ccc"
      },
      focus: true,
      width: 550
    });
    
    modal.show();
  
}

